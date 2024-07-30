#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,DB Identifier,Cluster Name,Role,Status,Engine,Engine Version,Size,CPUs,RAM,Allocated Storage,Endpoint,Reader Endpoint,Writer Endpoint,Availability Zone,Is Disk Encrypted,KMS Key ID,Is Automated Backup Enabled,Security Group Names,Open Ports" > rds_instances.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching RDS instances in $region"
    
    # Describe RDS instances in the region
    instances=$(aws rds describe-db-instances --region $region --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,EngineVersion,AllocatedStorage,Endpoint.Address,DBSecurityGroups[*].DBSecurityGroupName,VpcSecurityGroups[*].VpcSecurityGroupId,DBInstanceStatus,AvailabilityZone,StorageEncrypted,KmsKeyId,DBInstanceArn,BackupRetentionPeriod]' --output json)
    
    # Loop through each instance to get additional details
    echo "$instances" | jq -c '.[]' | while read instance; do
        db_identifier=$(echo $instance | jq -r '.[0]')
        size=$(echo $instance | jq -r '.[1]')
        engine=$(echo $instance | jq -r '.[2]')
        engine_version=$(echo $instance | jq -r '.[3]')
        allocated_storage=$(echo $instance | jq -r '.[4]')
        endpoint=$(echo $instance | jq -r '.[5]')
        db_security_groups=$(echo $instance | jq -r '.[6][]')
        vpc_security_groups=$(echo $instance | jq -r '.[7][]')
        status=$(echo $instance | jq -r '.[8]')
        availability_zone=$(echo $instance | jq -r '.[9]')
        storage_encrypted=$(echo $instance | jq -r '.[10]')
        kms_key_arn=$(echo $instance | jq -r '.[11]')
        db_instance_arn=$(echo $instance | jq -r '.[12]')
        backup_retention_period=$(echo $instance | jq -r '.[13]')
        
        # Filter out DocumentDB instances
        if [[ "$engine" == "docdb" || "$engine" == "docdb-elastic" ]]; then
            continue
        fi
        
        # Convert storage_encrypted to Yes or No
        if [ "$storage_encrypted" = "true" ]; then
            storage_encrypted="Yes"
        else
            storage_encrypted="No"
        fi
        
        # Extract KMS Key ID from ARN
        kms_key_id=$(echo $kms_key_arn | awk -F'/' '{print $NF}')
        
        # Determine if automated backups are enabled
        if [ "$backup_retention_period" -gt 0 ]; then
            is_automated_backup_enabled="Yes"
        else
            is_automated_backup_enabled="No"
        fi
        
        # Get the cluster identifier if the instance is part of a cluster
        cluster_identifier=$(aws rds describe-db-clusters --region $region --query "DBClusters[?contains(DBClusterMembers[?DBInstanceIdentifier=='$db_identifier'].DBInstanceIdentifier, '$db_identifier')].[DBClusterIdentifier]" --output text)
        
        # Get the role (whether it's part of a cluster or a standalone instance)
        if [ -n "$cluster_identifier" ]; then
            role="Cluster"
            # Get reader and writer endpoints for the cluster
            reader_endpoint=$(aws rds describe-db-clusters --db-cluster-identifier $cluster_identifier --region $region --query "DBClusters[0].ReaderEndpoint" --output text)
            writer_endpoint=$(aws rds describe-db-clusters --db-cluster-identifier $cluster_identifier --region $region --query "DBClusters[0].Endpoint" --output text)
        else
            role="Standalone"
            reader_endpoint=""
            writer_endpoint=""
        fi
        
        # Extract CPUs and RAM from DB instance class
        instance_class_info=$(aws rds describe-orderable-db-instance-options --db-instance-class $size --engine $engine --query "OrderableDBInstanceOptions[0].[vCPUs,Memory]" --output json --region $region)
        cpus=$(echo $instance_class_info | jq -r '.[0]')
        ram=$(echo $instance_class_info | jq -r '.[1]')
        
        # Get security group details
        security_group_names=""
        open_ports=""
        
        all_security_groups=$(echo "$db_security_groups $vpc_security_groups")
        
        for sg in $all_security_groups; do
            if [ -n "$sg" ]; then
                security_group_name=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].GroupName' --output text --region $region)
                security_group_names+="$security_group_name "
                
                ports=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].IpPermissions[*].FromPort' --output json --region $region | jq -r '.[][]')
                open_ports+="$ports "
            fi
        done

        # Remove duplicates and sort the open ports
        open_ports=$(echo $open_ports | tr ' ' '\n' | sort -n | uniq | tr '\n' ' ')
        
        # Append the instance details to the CSV file
        echo "$account_id,$region,$db_identifier,$cluster_identifier,$role,$status,$engine,$engine_version,$size,$cpus,$ram,$allocated_storage,$endpoint,$reader_endpoint,$writer_endpoint,$availability_zone,$storage_encrypted,$kms_key_id,$is_automated_backup_enabled,\"$security_group_names\",\"$open_ports\"" >> rds_instances.csv
    done
done

echo "Completed. Data saved in rds_instances.csv"

