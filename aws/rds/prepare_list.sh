#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,DB Identifier,Cluster Name,Role,Status,Engine,Size,CPUs,RAM,Allocated Storage,Endpoint,Availability Zone,Is Disk Encrypted,KMS Key ID,Security Group Name,Open Ports" > rds_instances.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching RDS instances in $region"
    
    # Describe RDS instances in the region
    instances=$(aws rds describe-db-instances --region $region --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,AllocatedStorage,Endpoint.Address,DBSecurityGroups[*].DBSecurityGroupName,VpcSecurityGroups[*].VpcSecurityGroupId,DBInstanceStatus,AvailabilityZone,StorageEncrypted,KmsKeyId,DBInstanceArn]' --output json)
    
    # Loop through each instance to get additional details
    echo "$instances" | jq -c '.[]' | while read instance; do
        db_identifier=$(echo $instance | jq -r '.[0]')
        size=$(echo $instance | jq -r '.[1]')
        engine=$(echo $instance | jq -r '.[2]')
        allocated_storage=$(echo $instance | jq -r '.[3]')
        endpoint=$(echo $instance | jq -r '.[4]')
        db_security_groups=$(echo $instance | jq -r '.[5][]')
        vpc_security_groups=$(echo $instance | jq -r '.[6][]')
        status=$(echo $instance | jq -r '.[7]')
        availability_zone=$(echo $instance | jq -r '.[8]')
        storage_encrypted=$(echo $instance | jq -r '.[9]')
        kms_key_arn=$(echo $instance | jq -r '.[10]')
        db_instance_arn=$(echo $instance | jq -r '.[11]')
        
        # Convert storage_encrypted to Yes or No
        if [ "$storage_encrypted" = "true" ]; then
            storage_encrypted="Yes"
        else
            storage_encrypted="No"
        fi
        
        # Extract KMS Key ID from ARN
        kms_key_id=$(echo $kms_key_arn | awk -F'/' '{print $NF}')
        
        # Get the cluster identifier if the instance is part of a cluster
        cluster_identifier=$(aws rds describe-db-clusters --region $region --query "DBClusters[?contains(DBClusterMembers[?DBInstanceIdentifier=='$db_identifier'].DBInstanceIdentifier, '$db_identifier')].[DBClusterIdentifier]" --output text)
        
        # Get the role (whether it's part of a cluster or a standalone instance)
        if [ -n "$cluster_identifier" ]; then
            role="Cluster"
        else
            role="Standalone"
        fi
        
        # Extract CPUs and RAM from DB instance class
        instance_class_info=$(aws rds describe-orderable-db-instance-options --db-instance-class $size --engine $engine --query "OrderableDBInstanceOptions[0].[vCPUs,Memory]" --output json --region $region)
        cpus=$(echo $instance_class_info | jq -r '.[0]')
        ram=$(echo $instance_class_info | jq -r '.[1]')
        
        # Get security group details
        security_group_names=""
        open_ports=""
        
        if [ -n "$db_security_groups" ]; then
            for sg in $db_security_groups; do
                security_group_name=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].GroupName' --output text --region $region)
                security_group_names+="$security_group_name "
                open_ports+=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].IpPermissions[*].FromPort' --output text --region $region)" "
            done
        fi
        
        if [ -n "$vpc_security_groups" ]; then
            for sg in $vpc_security_groups; do
                security_group_name=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].GroupName' --output text --region $region)
                security_group_names+="$security_group_name "
                open_ports+=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].IpPermissions[*].FromPort' --output text --region $region)" "
            done
        fi

        # Append the instance details to the CSV file
        echo "$account_id,$region,$db_identifier,$cluster_identifier,$role,$status,$engine,$size,$cpus,$ram,$allocated_storage,$endpoint,$availability_zone,$storage_encrypted,$kms_key_id,$security_group_names,$open_ports" >> rds_instances.csv
    done
done

echo "Completed. Data saved in rds_instances.csv"
