#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,Bucket Name,Creation Date,Owner,Number of Objects,Total Size (Bytes),Is Versioning Enabled,Is Logging Enabled,Is Encryption Enabled,Access Control List (ACL),Bucket Policy,Replication Status" > s3_buckets.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# List S3 buckets (Note: S3 is a global service, so no region is specified)
buckets=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)

# Loop through each bucket
for bucket in $buckets; do
    echo "Processing bucket: $bucket"
    
    # Get bucket location
    region=$(aws s3api get-bucket-location --bucket $bucket --query 'LocationConstraint' --output text)
    # Handle the case where the location is null (us-east-1)
    if [ "$region" == "None" ]; then
        region=""
    fi

    # Get bucket creation date
    creation_date=$(aws s3api list-buckets --query "Buckets[?Name=='$bucket'].CreationDate" --output text)
    
    # Get bucket owner
    owner=$(aws s3api get-bucket-acl --bucket $bucket --query 'Owner.DisplayName' --output text)
    
    # Get number of objects and total size in the bucket
    number_of_objects=$(aws s3api list-objects --bucket $bucket --query 'length(Contents)' --output text 2>/dev/null)
    total_size=$(aws s3api list-objects --bucket $bucket --query 'Contents[].Size' --output text | awk '{s+=$1} END {print s}')
    # Default to 0 if no objects
    number_of_objects=${number_of_objects:-0}
    total_size=${total_size:-0}
    
    # Check if versioning is enabled
    versioning_status=$(aws s3api get-bucket-versioning --bucket $bucket --query 'Status' --output text)
    if [ "$versioning_status" == "Enabled" ]; then
        is_versioning_enabled="Yes"
    else
        is_versioning_enabled="No"
    fi
    
    # Check if logging is enabled
    logging_status=$(aws s3api get-bucket-logging --bucket $bucket --query 'LoggingEnabled.TargetBucket' --output text)
    if [ -n "$logging_status" ]; then
        is_logging_enabled="Yes"
    else
        is_logging_enabled="No"
    fi
    
    # Check if encryption is enabled
    encryption_status=$(aws s3api get-bucket-encryption --bucket $bucket --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null)
    if [ -n "$encryption_status" ]; then
        is_encryption_enabled="Yes"
    else
        is_encryption_enabled="No"
    fi
    
    # Get the bucket ACL
    acl=$(aws s3api get-bucket-acl --bucket $bucket --query 'Grants' --output json | tr -d '\n' | sed 's/"/""/g')
    
    # Get the bucket policy
    policy=$(aws s3api get-bucket-policy --bucket $bucket --query 'Policy' --output text 2>/dev/null | tr -d '\n' | sed 's/"/""/g')
    if [ $? -ne 0 ]; then
        policy="No Policy"
    fi
    
    # Check if replication is enabled
    replication_status=$(aws s3api get-bucket-replication --bucket $bucket --query 'ReplicationConfiguration.Rules[0].Status' --output text 2>/dev/null)
    if [ -n "$replication_status" ]; then
        replication_status="Yes"
    else
        replication_status="No"
    fi
    
    # Append the bucket details to the CSV file
    echo "$account_id,$region,$bucket,$creation_date,$owner,$number_of_objects,$total_size,$is_versioning_enabled,$is_logging_enabled,$is_encryption_enabled,\"$acl\",\"$policy\",$replication_status" >> s3_buckets.csv
done

echo "Completed. Data saved in s3_buckets.csv"

