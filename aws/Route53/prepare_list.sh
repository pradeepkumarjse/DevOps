#!/bin/bash

# Define the output CSV file
output_file="route53_inventory.csv"

# Write the header row to the CSV file
echo "AWS Account ID,Region,Hosted Zone ID,Hosted Zone Name,Record Set Name,Record Type,TTL,Record Value" > $output_file

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Region is global for Route 53, so we'll use us-east-1 as a placeholder
region="us-east-1"

# Get a list of all hosted zones
hosted_zones=$(aws route53 list-hosted-zones --query 'HostedZones[*].[Id,Name]' --output json)

# Loop through each hosted zone
echo "$hosted_zones" | jq -c '.[]' | while read zone; do
    hosted_zone_id=$(echo $zone | jq -r '.[0]' | awk -F/ '{print $3}')
    hosted_zone_name=$(echo $zone | jq -r '.[1]')

    # Get a list of all record sets in the hosted zone
    record_sets=$(aws route53 list-resource-record-sets --hosted-zone-id $hosted_zone_id --query 'ResourceRecordSets[*].[Name,Type,TTL,ResourceRecords[*].Value]' --output json)

    # Loop through each record set
    echo "$record_sets" | jq -c '.[]' | while read record_set; do
        record_name=$(echo $record_set | jq -r '.[0]')
        record_type=$(echo $record_set | jq -r '.[1]')
        ttl=$(echo $record_set | jq -r '.[2]')
        record_values=$(echo $record_set | jq -r '.[3][]')
        
        # Combine multiple record values into a single string
        record_value=$(echo "$record_values" | paste -sd ";" -)

        # Write the record set details to the CSV file
        echo "$account_id,$region,$hosted_zone_id,$hosted_zone_name,$record_name,$record_type,$ttl,\"$record_value\"" >> $output_file
    done
done

echo "Completed. Data saved in $output_file"
