import boto3
import json
import requests

# Source and target regions
source_region = 'us-east-1'
target_region = 'us-east-2'
source_access_key = ''
source_secret_key = ''

# Initialize Boto3 clients for source and target regions
lambda_client_source = boto3.client('lambda', region_name=source_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
lambda_client_target = boto3.client('lambda', region_name=target_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
api_client_source = boto3.client('apigateway', region_name=source_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
api_client_target = boto3.client('apigateway', region_name=target_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)

def list_lambda_functions(lambda_client):
    response = lambda_client.list_functions()
    print(response)
    functions = response['Functions']
    while 'NextMarker' in response:
        response = lambda_client.list_functions(Marker=response['NextMarker'])
        functions.extend(response['Functions'])
    return functions

def get_lambda_function(lambda_client, function_name):
    response = lambda_client.get_function(FunctionName=function_name)
    return response

def create_lambda_function(lambda_client, function_details):
    code = function_details['Code']
    code_config = {}

    if 'S3Bucket' in code and 'S3Key' in code:
        code_config['S3Bucket'] = code['S3Bucket']
        code_config['S3Key'] = code['S3Key']
        if 'S3ObjectVersion' in code:
            code_config['S3ObjectVersion'] = code['S3ObjectVersion']
    elif 'Location' in code:
        # Download the code package from the Location URL
        response = requests.get(code['Location'])
        zip_file = response.content

        code_config['ZipFile'] = zip_file
    else:
        # If code source is not available, raise an error
        raise ValueError("Code source is not available")

    response = lambda_client.create_function(
        FunctionName=function_details['Configuration']['FunctionName'],
        Runtime=function_details['Configuration']['Runtime'],
        Role=function_details['Configuration']['Role'],
        Handler=function_details['Configuration']['Handler'],
        Code=code_config,
        Description=function_details['Configuration']['Description'],
        Timeout=function_details['Configuration']['Timeout'],
        MemorySize=function_details['Configuration']['MemorySize'],
        Publish=True,
        VpcConfig=function_details['Configuration'].get('VpcConfig', {}),
        Environment=function_details['Configuration'].get('Environment', {}),
        Tags=function_details.get('Tags', {}),
        TracingConfig=function_details['Configuration'].get('TracingConfig', {})
    )
    return response
    
def lambda_handler(event, context):
    
    # List all Lambda functions in the source account
    functions = list_lambda_functions(lambda_client_source)
    
    print(functions)
    
    
    # Copy each function to the destination account
    for function in functions:
        function_name = function['FunctionName']
        function_details = get_lambda_function(lambda_client_source, function_name)
        try:
            create_lambda_function(lambda_client_target, function_details)
            print(f"Copied function: {function_name}")
        except Exception as e:
            print(f"Failed to copy function: {function_name}. Error: {str(e)}")


    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }


lambda_handler(None,None)
