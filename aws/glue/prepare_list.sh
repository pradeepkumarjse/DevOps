#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,Job Name,Role,Created On,Last Modified On,Allocated Capacity,Timeout,Max Retries,Max Capacity,Glue Version,Runtime,Data Processing Units" > glue_jobs.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching Glue jobs in $region"
    
    # List all Glue jobs in the region
    jobs=$(aws glue get-jobs --region $region --query 'Jobs[*]' --output json)
    
    # Loop through each job to get additional details
    echo "$jobs" | jq -c '.[]' | while read job; do
        job_name=$(echo $job | jq -r '.Name')
        role=$(echo $job | jq -r '.Role')
        created_on=$(echo $job | jq -r '.CreatedOn')
        last_modified_on=$(echo $job | jq -r '.LastModifiedOn')
        allocated_capacity=$(echo $job | jq -r '.AllocatedCapacity // empty')
        timeout=$(echo $job | jq -r '.Timeout')
        max_retries=$(echo $job | jq -r '.MaxRetries')
        max_capacity=$(echo $job | jq -r '.MaxCapacity // empty')
        glue_version=$(echo $job | jq -r '.GlueVersion // empty')
        
        # Extract runtime and DPUs correctly
        runtime=$(echo $job | jq -r '.Command.PythonVersion // empty')
        if [ "$runtime" != "empty" ]; then
            runtime="Python $runtime"
        else
            runtime="N/A"
        fi

        dpu=$(echo $job | jq -r '.AllocatedCapacity // empty')

        # Replace null values with default text "N/A"
        allocated_capacity=${allocated_capacity:-"N/A"}
        max_capacity=${max_capacity:-"N/A"}
        glue_version=${glue_version:-"N/A"}
        dpu=${dpu:-"N/A"}

        # Append the job details to the CSV file
        echo "$account_id,$region,$job_name,$role,$created_on,$last_modified_on,$allocated_capacity,$timeout,$max_retries,$max_capacity,$glue_version,$runtime,$dpu" >> glue_jobs.csv
    done
done

echo "Completed. Data saved in glue_jobs.csv"
