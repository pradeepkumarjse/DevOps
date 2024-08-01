#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,Function Name,Runtime,Handler,Role,Description,Timeout (seconds),Memory Size (MB),Last Modified,Code Size (Bytes),Code Sha256,Version,VPC Config,Environment Variables,Tags,Triggers ARN" > lambda_functions.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching Lambda functions in $region"
    
    # List all Lambda functions in the region
    functions=$(aws lambda list-functions --region $region --query 'Functions[*]' --output json)
    
    # Loop through each function to get additional details
    echo "$functions" | jq -c '.[]' | while read function; do
        function_name=$(echo $function | jq -r '.FunctionName')
        runtime=$(echo $function | jq -r '.Runtime')
        handler=$(echo $function | jq -r '.Handler')
        role=$(echo $function | jq -r '.Role')
        description=$(echo $function | jq -r '.Description // empty')
        timeout=$(echo $function | jq -r '.Timeout')
        memory_size=$(echo $function | jq -r '.MemorySize')
        last_modified=$(echo $function | jq -r '.LastModified')
        code_size=$(echo $function | jq -r '.CodeSize')
        code_sha256=$(echo $function | jq -r '.CodeSha256')
        version=$(echo $function | jq -r '.Version')
        
        # Convert code size to KB using awk
        code_size_kb=$(awk "BEGIN {print $code_size}")

        # Get VPC config
        vpc_config=$(echo $function | jq -r '.VpcConfig | if . then "Subnets: " + (.SubnetIds | join(",")) + "; SecurityGroups: " + (.SecurityGroupIds | join(",")) else "None" end')
        
        # Get environment variables
        environment_variables=$(echo $function | jq -r '.Environment.Variables | if . then to_entries | map("\(.key)=\(.value)") | join(",") else "None" end')
        
        # Get tags
        tags=$(aws lambda list-tags --resource arn:aws:lambda:$region:$account_id:function:$function_name --query 'Tags' --output json --region $region)
        tags=$(echo $tags | jq -r 'if . then to_entries | map("\(.key)=\(.value)") | join(",") else "None" end')
        
        # Get triggers and handle potential errors
        triggers=$(aws lambda get-policy --function-name $function_name --query 'Policy' --output text --region $region 2>/dev/null)
        if [ -z "$triggers" ]; then
            triggers="None"
        else
            triggers=$(echo $triggers | jq -r '.Statement[].Condition.ArnLike."AWS:SourceArn"' | tr '\n' ',' | sed 's/,$//')
        fi
        
        # Append the function details to the CSV file
        echo "$account_id,$region,$function_name,$runtime,$handler,$role,\"$description\",$timeout,$memory_size,$last_modified,$code_size_kb,$code_sha256,$version,\"$vpc_config\",\"$environment_variables\",\"$tags\",\"$triggers\"" >> lambda_functions.csv
    done
done

echo "Completed. Data saved in lambda_functions.csv"

