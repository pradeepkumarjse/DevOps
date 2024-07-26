#!/bin/bash

# Enable error handling
set -e
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Define column headers
echo "AWS Account ID,Resource Name,Resource ARN,Instance type,Status,AWS Region,Availability Zone,Public IP,Is Elastic IP,Private IP,DNS name,Security group name,Opened Port,Key Name,Platform,OS Version,CPUs,RAM,DISK Space,Taking Daily Backup?,Is Disk Encrypted,KMS key ID" > ec2_instances.csv

# Get the AWS Account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)
if [ $? -ne 0 ]; then
    echo "Failed to get AWS Account ID"
    exit 1
fi

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)
if [ $? -ne 0 ]; then
    echo "Failed to get AWS regions"
    exit 1
fi

# Function to get open ports from a security group
get_open_ports() {
    local sg_id=$1
    local region=$2
    local open_ports
    open_ports=$(aws ec2 describe-security-groups --region "$region" --group-ids "$sg_id" --query 'SecurityGroups[].IpPermissions[].FromPort' --output text | tr '\n' ',')
    if [ $? -ne 0 ]; then
        echo "Failed to get open ports for security group $sg_id in region $region"
        exit 1
    fi
    echo "${open_ports%,}"
}

# Loop through each region
for region in $regions; do
    region=$(echo $region | tr -d '"')  # Strip any extraneous quotes
    echo "Fetching instances in region: $region"
    
    # Describe instances in the region
    instances=$(aws ec2 describe-instances --region $(echo $region | tr -d '"') --query 'Reservations[].Instances[]' --output json)
    if [ $? -ne 0 ]; then
        echo "Failed to describe instances in region $region"
        exit 1
    fi
    
    # Process each instance
    echo "$instances" | jq -r --arg region $(echo $region | tr -d '"') --arg account_id "$account_id" '
    .[] | [
        $account_id,
        (try (.Tags[]? | select(.Key == "Name") | .Value) // "N/A"),
        ("arn:aws:ec2:" + $region + ":" + $account_id + ":instance/" + .InstanceId),        
        .InstanceType,
        .State.Name,
        $region,
        .Placement.AvailabilityZone,
        (.PublicIpAddress // "N/A"),
        (try (.ElasticGpuAssociations[0].ElasticGpuId // "N/A")),
        (.PrivateIpAddress // "N/A"),
        (.PublicDnsName // "N/A"),
        (try (.SecurityGroups | map(.GroupName) | join(";")) // "N/A"),
        (try (.SecurityGroups | map(.GroupId) | join(";")) // "N/A"),
        (.KeyName // "N/A"),
        (.PlatformDetails // "N/A"),
        (.Architecture // "N/A"),
        (try (.CpuOptions.CoreCount // "N/A")),
        (try (.MemoryInfo.SizeInMiB // "N/A")),
        (try (.BlockDeviceMappings | map(.Ebs.VolumeSize) | join(";")) // "N/A"),
        "N/A",  # Placeholder for Taking Daily Backup?
        (try (.BlockDeviceMappings | map(.Ebs.Encrypted) | join(";")) // "N/A"),
        (try (.BlockDeviceMappings | map(.Ebs.KmsKeyId) | join(";")) // "N/A")
    ] | @csv' | while IFS=',' read -r account_id name instance_id instance_type state region az public_ip is_elastic_ip private_ip dns_name sg_names sg_ids key_name platform architecture cpus ram disk_space taking_backup is_encrypted kms_key_id; do
        # Fetch open ports for each security group
        open_ports=""
        for sg_id in $(echo "$sg_ids" | tr ';' ' '); do
            ports=$(get_open_ports $(echo $sg_id | tr -d '"') $(echo $region | tr -d '"'))
            open_ports="${open_ports}${ports};"
        done
        open_ports="${open_ports%;}"
        
        # Output to CSV
        echo "$account_id,$name,$instance_id,$instance_type,$state,$region,$az,$public_ip,$is_elastic_ip,$private_ip,$dns_name,$sg_names,$open_ports,$key_name,$platform,$architecture,$cpus,$ram,$disk_space,$taking_backup,$is_encrypted,$kms_key_id" >> ec2_instances.csv
    done
done

echo "Completed. Data saved in ec2_instances.csv"
