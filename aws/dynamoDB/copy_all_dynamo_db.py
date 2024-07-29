import boto3
from botocore.exceptions import ClientError

source_region = 'us-east-2'
destination_region = 'us-east-1'
source_access_key=''
source_secret_key=''

source_dynamodb = boto3.client(
    'dynamodb',
    region_name=source_region,
    aws_access_key_id=source_access_key,
    aws_secret_access_key=source_secret_key
)
destination_dynamodb = boto3.client(
    'dynamodb',
    region_name=destination_region,
    aws_access_key_id=source_access_key,
    aws_secret_access_key=source_secret_key
)

def copy_table(source_table_name, destination_table_name):
    source_dynamodb_resource = boto3.resource(
        'dynamodb',
        region_name=source_region,
        aws_access_key_id=source_access_key,
        aws_secret_access_key=source_secret_key
    )
    destination_dynamodb_resource = boto3.resource(
        'dynamodb',
        region_name=destination_region,
        aws_access_key_id=source_access_key,
        aws_secret_access_key=source_secret_key
    )

    source_table = source_dynamodb_resource.Table(source_table_name)
    destination_table = destination_dynamodb_resource.Table(destination_table_name)

    # Handle pagination for large tables
    response = source_table.scan()
    items = response['Items']
    while 'LastEvaluatedKey' in response:
        response = source_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        items.extend(response['Items'])

    # Batch write to destination table
    with destination_table.batch_writer() as batch:
        for item in items:
            batch.put_item(Item=item)

def create_destination_table(source_table_name, destination_table_name):
    try:
        # Get the source table description
        table_description = source_dynamodb.describe_table(TableName=source_table_name)['Table']

        # Create the destination table with the same key schema, attribute definitions, GSIs, and LSIs
        table_params = {
            'TableName': destination_table_name,
            'KeySchema': table_description['KeySchema'],
            'AttributeDefinitions': table_description['AttributeDefinitions'],
            'ProvisionedThroughput': {
                'ReadCapacityUnits': table_description['ProvisionedThroughput']['ReadCapacityUnits'],
                'WriteCapacityUnits': table_description['ProvisionedThroughput']['WriteCapacityUnits']
            },
            'BillingMode': table_description['BillingModeSummary']['BillingMode'] if 'BillingModeSummary' in table_description else 'PROVISIONED'
        }

        if 'GlobalSecondaryIndexes' in table_description:
            table_params['GlobalSecondaryIndexes'] = table_description['GlobalSecondaryIndexes']
            for gsi in table_params['GlobalSecondaryIndexes']:
                gsi.pop('IndexStatus', None)
                gsi.pop('ProvisionedThroughput', None)
                gsi.pop('IndexSizeBytes', None)
                gsi.pop('ItemCount', None)
                gsi['ProvisionedThroughput'] = {
                    'ReadCapacityUnits': 5,
                    'WriteCapacityUnits': 5
                }

        if 'LocalSecondaryIndexes' in table_description:
            table_params['LocalSecondaryIndexes'] = table_description['LocalSecondaryIndexes']
            for lsi in table_params['LocalSecondaryIndexes']:
                lsi.pop('IndexSizeBytes', None)
                lsi.pop('ItemCount', None)

        destination_dynamodb.create_table(**table_params)

        # Wait for the table to be created
        waiter = destination_dynamodb.get_waiter('table_exists')
        waiter.wait(TableName=destination_table_name)

        # Set deletion protection if it exists in the source table
        if 'DeletionProtectionEnabled' in table_description and table_description['DeletionProtectionEnabled']:
            destination_dynamodb.update_table(
                TableName=destination_table_name,
                DeletionProtectionEnabled=True
            )

        # Copy tags from source to destination table
        source_tags = source_dynamodb.list_tags_of_resource(
            ResourceArn=table_description['TableArn']
        ).get('Tags', [])
        
        if source_tags:
            destination_table_description = destination_dynamodb.describe_table(TableName=destination_table_name)['Table']
            destination_dynamodb.tag_resource(
                ResourceArn=destination_table_description['TableArn'],
                Tags=source_tags
            )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceInUseException':
            print(f"Table {destination_table_name} already exists in {destination_region}")
        else:
            raise

def copy_all_tables(source_region, destination_region):
    # List all tables in the source region
    source_tables = source_dynamodb.list_tables()['TableNames']
    for table_name in source_tables:
        print(f"Copying table {table_name} from {source_region} to {destination_region}...")
        destination_table_name = table_name  # You can change this if you want to rename the table
        create_destination_table(table_name, destination_table_name)
        copy_table(table_name, destination_table_name)
        print(f"Table {table_name} copied successfully.")

copy_all_tables(source_region, destination_region)
