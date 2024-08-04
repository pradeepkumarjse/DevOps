#!/bin/bash

# Define the output CSV file
output_file="static_ip_inventory.csv"

# Write the header row to the CSV file
echo "AWS Account ID,AWS Region,Name,Elastic IP,Attached Instance ID,Allocation ID,Public IP,Private IP,Domain,Network Interface ID,Association ID" > $output_file

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching Elastic IPs in $region"
    
    # Describe Elastic IPs in the region
    eips=$(aws ec2 describe-addresses --region $region --query 'Addresses[*].[InstanceId,PublicIp,AllocationId,PrivateIpAddress,Domain,NetworkInterfaceId,AssociationId,Tags]' --output json)
    
    # Loop through each Elastic IP to get details
    echo "$eips" | jq -c '.[]' | while read -r eip; do
        instance_id=$(echo $eip | jq -r '.[0]')
        public_ip=$(echo $eip | jq -r '.[1]')
        allocation_id=$(echo $eip | jq -r '.[2]')
        private_ip=$(echo $eip | jq -r '.[3]')
        domain=$(echo $eip | jq -r '.[4]')
        network_interface_id=$(echo $eip | jq -r '.[5]')
        association_id=$(echo $eip | jq -r '.[6]')
        
        # Extract the "Name" tag if it exists
        name=$(echo $eip | jq -r '.[7][] | select(.Key == "Name") | .Value' 2>/dev/null)
        if [ -z "$name" ]; then
            name="N/A"
        fi
        
        # Write the Elastic IP details to the CSV file
        echo "$account_id,$region,$name,$public_ip,$instance_id,$allocation_id,$public_ip,$private_ip,$domain,$network_interface_id,$association_id" >> $output_file
    done
done

echo "Completed. Data saved in $output_file"
