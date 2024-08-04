#!/bin/bash

# Define column headers
echo "AWS Account ID,AWS Region,VPC ID,VPC Name,State,CIDR Block,Is Default,Instance Tenancy,Subnets,Route Tables,Security Groups,NAT Gateways,VPC Endpoints" > vpc_inventory.csv

# Get the AWS account ID
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get a list of AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Loop through each region
for region in $regions; do
    echo "Fetching VPCs in $region"
    
    # Describe VPCs in the region
    vpcs=$(aws ec2 describe-vpcs --region $region --query 'Vpcs[*].[VpcId,State,CidrBlock,IsDefault,InstanceTenancy]' --output json)
    
    # Loop through each VPC to get additional details
    echo "$vpcs" | jq -c '.[]' | while read vpc; do
        vpc_id=$(echo $vpc | jq -r '.[0]')
        state=$(echo $vpc | jq -r '.[1]')
        cidr_block=$(echo $vpc | jq -r '.[2]')
        is_default=$(echo $vpc | jq -r '.[3]')
        instance_tenancy=$(echo $vpc | jq -r '.[4]')
        
        # Get the VPC name (if it exists)
        vpc_name=$(aws ec2 describe-tags --region $region --filters "Name=resource-id,Values=$vpc_id" "Name=key,Values=Name" --query 'Tags[0].Value' --output text 2>/dev/null || echo "N/A")
        
        # Get the subnets in the VPC with names
        subnets=$(aws ec2 describe-subnets --region $region --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0]]' --output json)
        subnets=$(echo $subnets | jq -r '.[] | .[0] + " (" + (. | .[1] // "No Name") + ")"' | tr '\n' ',' | sed 's/,$//')
        
        # Get the route tables in the VPC with names
        route_tables=$(aws ec2 describe-route-tables --region $region --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' --output json)
        route_tables=$(echo $route_tables | jq -r '.[] | .[0] + " (" + (. | .[1] // "No Name") + ")"' | tr '\n' ',' | sed 's/,$//')
        
        # Get the security groups in the VPC with names
        security_groups=$(aws ec2 describe-security-groups --region $region --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[*].[GroupId,GroupName]' --output json)
        security_groups=$(echo $security_groups | jq -r '.[] | .[0] + " (" + .[1] + ")"' | tr '\n' ',' | sed 's/,$//')
        
        # Get the NAT Gateways in the VPC with names
        nat_gateways=$(aws ec2 describe-nat-gateways --region $region --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[*].[NatGatewayId,Tags[?Key==`Name`].Value|[0]]' --output json)
        nat_gateways=$(echo $nat_gateways | jq -r '.[] | .[0] + " (" + (. | .[1] // "No Name") + ")"' | tr '\n' ',' | sed 's/,$//')
        
        # Get the VPC Endpoints in the VPC with names
        vpc_endpoints=$(aws ec2 describe-vpc-endpoints --region $region --filters "Name=vpc-id,Values=$vpc_id" --query 'VpcEndpoints[*].[VpcEndpointId,Tags[?Key==`Name`].Value|[0]]' --output json)
        vpc_endpoints=$(echo $vpc_endpoints | jq -r '.[] | .[0] + " (" + (. | .[1] // "No Name") + ")"' | tr '\n' ',' | sed 's/,$//')
        
        # Append the VPC details to the CSV file
        echo "$account_id,$region,$vpc_id,\"$vpc_name\",$state,$cidr_block,$is_default,$instance_tenancy,\"$subnets\",\"$route_tables\",\"$security_groups\",\"$nat_gateways\",\"$vpc_endpoints\"" >> vpc_inventory.csv
    done
done

echo "Completed. Data saved in vpc_inventory.csv"
