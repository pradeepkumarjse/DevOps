#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,API Gateway ID,Name,Description,Created Date,Endpoint Type,ARN,Resource Policy,Tags" > api_gateway_instances.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching API Gateways in $region"
    
    # Describe API Gateways in the region
    apis=$(aws apigateway get-rest-apis --region $region --query 'items[*].[id,name,description,createdDate,endpointConfiguration.types]' --output json)
    
    # Loop through each API Gateway to get additional details
    echo "$apis" | jq -c '.[]' | while read api; do
        api_id=$(echo $api | jq -r '.[0]')
        name=$(echo $api | jq -r '.[1] // "NA"')  # Default to "No Name" if name is null
        description=$(echo $api | jq -r '.[2] // "NA"')  # Default to "No Description" if description is null
        created_date=$(echo $api | jq -r '.[3] // "NA"')  # Default to "No Date" if createdDate is null
        endpoint_type=$(echo $api | jq -r '.[4][0] // "NA"')  # Default to "No Endpoint Type" if endpointConfiguration is null
        
        # Construct ARN for API Gateway
        arn="arn:aws:apigateway:$region::/restapis/$api_id"
        
        # Get the resource policy for the API Gateway
        resource_policy=$(aws apigateway get-rest-api --region $region --rest-api-id $api_id --query 'policy' --output text)
        
        # Handle cases where the resource policy is empty
        if [ -z "$resource_policy" ]; then
            resource_policy="No Policy"
        else
            # Clean up the JSON string by removing escape sequences
            resource_policy=$(echo $resource_policy | sed 's/\\//g' | sed 's/"/""/g')
        fi
        
        # Get tags - updated to correct the ARN format
        tags=$(aws apigateway get-tags --resource-arn $arn --region $region --output json | jq -r '.Tags | to_entries | map("\(.key):\(.value)") | join(", ")')
        
        # Append the API Gateway details to the CSV file
        echo "$account_id,$region,$api_id,$name,\"$description\",$created_date,$endpoint_type,$arn,\"$resource_policy\",\"$tags\"" >> api_gateway_instances.csv
    done
done

echo "Completed. Data saved in api_gateway_instances.csv"
