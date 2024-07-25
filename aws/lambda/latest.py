import boto3
import json
import requests
from botocore.exceptions import ClientError

# Source and target regions
source_region = 'us-east-1'
target_region = 'us-east-2'
source_access_key = ''
source_secret_key = ''
account_id = ''  # Replace with your AWS account ID

# Initialize Boto3 clients for source and target regions
lambda_client_source = boto3.client('lambda', region_name=source_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
lambda_client_target = boto3.client('lambda', region_name=target_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
api_client_source = boto3.client('apigateway', region_name=source_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
api_client_target = boto3.client('apigateway', region_name=target_region, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)

def list_lambda_functions(lambda_client):
    functions = []
    response = lambda_client.list_functions()
    functions.extend(response['Functions'])
    while 'NextMarker' in response:
        response = lambda_client.list_functions(Marker=response['NextMarker'])
        functions.extend(response['Functions'])
    return functions

def get_lambda_function(lambda_client, function_name):
    return lambda_client.get_function(FunctionName=function_name)

def create_lambda_function(lambda_client, function_details):
    code_config = {}
    code = function_details['Code']
    if 'S3Bucket' in code and 'S3Key' in code:
        code_config = {k: code[k] for k in ('S3Bucket', 'S3Key', 'S3ObjectVersion') if k in code}
    elif 'Location' in code:
        response = requests.get(code['Location'])
        code_config['ZipFile'] = response.content

    config = function_details['Configuration']
    return lambda_client.create_function(
        FunctionName=config['FunctionName'],
        Runtime=config['Runtime'],
        Role=config['Role'],
        Handler=config['Handler'],
        Code=code_config,
        Description=config['Description'],
        Timeout=config['Timeout'],
        MemorySize=config['MemorySize'],
        Publish=True,
        VpcConfig=config.get('VpcConfig', {}),
        Environment=config.get('Environment', {}),
        Tags=function_details.get('Tags', {}),
        TracingConfig=config.get('TracingConfig', {})
    )

def copy_resource_policy(api_client_source, api_client_target, source_api_id, target_api_id):
    try:
        # Retrieve the current policy from the source API
        policy_response = api_client_source.get_rest_api(restApiId=source_api_id)
        policy = policy_response.get('policy')

        if policy:
            policy = policy.replace('\\"', '"')
            # Convert policy string to JSON
            policy_json = json.loads(policy)
            # Use update_rest_api to apply the policy to the target API
            response = api_client_target.update_rest_api(
                restApiId=target_api_id,
                patchOperations=[
                    {
                        'op': 'replace',
                        'path': '/policy',
                        'value': json.dumps(policy_json)
                    }
                ]
            )
            print(f"Policy applied to target API. Response: {response}")
        else:
            print(f"No policy found for API {source_api_id}.")
    except json.JSONDecodeError as e:
        print(f"JSON decoding error: {str(e)}")
    except Exception as e:
        print(f"Error copying resource policy: {str(e)}")

def get_api_triggers(lambda_client, function_name):
    try:
        policy = json.loads(lambda_client.get_policy(FunctionName=function_name)['Policy'])
        return [stmt for stmt in policy['Statement'] if stmt['Principal'].get('Service') == 'apigateway.amazonaws.com']
    except lambda_client.exceptions.ResourceNotFoundException:
        return []

def get_resource_map(api_client, api_id):
    try:
        resources = api_client.get_resources(restApiId=api_id)
        return {res['id']: res for res in resources['items']}
    except api_client.exceptions.NotFoundException:
        print(f"API with ID {api_id} not found.")
        return {}

def copy_api(api_client_source, api_client_target, source_api_id, target_lambda_arn):
    source_resources = get_resource_map(api_client_source, source_api_id)
    if not source_resources:
        print(f"No resources found for API ID {source_api_id}")
        return None
    source_api = api_client_source.get_rest_api(restApiId=source_api_id)
    source_api_name = source_api.get('name', f"API-{source_api_id}")
    target_api = api_client_target.create_rest_api(name=source_api_name)
    target_api_id = target_api['id']
    target_resources = get_resource_map(api_client_target, target_api_id)

    print(target_resources)

    def get_root_resource(resources):
        for res_id, res in resources.items():
            if res.get('path') == '/':
                return res_id
        return None

    root_resource_id = get_root_resource(target_resources)

    def create_method(api_client, api_id, resource_id, method, integration_uri):       
        try:
            integration = api_client_source.get_integration(
                restApiId=source_api_id,
                resourceId=source_resources[src_res_id]['id'],
                httpMethod=method
            )
        except api_client_source.exceptions.NotFoundException:
            print(f"No integration found for method {method} on resource {source_resources[src_res_id]}")
            return

        api_client.put_method(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod=method,
            authorizationType='NONE'
        )
        api_client.put_integration(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod=method,
            type=integration['type'],
            integrationHttpMethod='POST',
            uri=integration_uri,
            requestParameters= integration.get('requestParameters', {}),
            requestTemplates =integration.get('requestTemplates', {}),
            passthroughBehavior = integration.get('passthroughBehavior'),
            cacheNamespace= integration.get('cacheNamespace'),
            cacheKeyParameters=integration.get('cacheKeyParameters', []),
            timeoutInMillis= integration.get('timeoutInMillis', 29000),
            contentHandling= integration.get('contentHandling', 'CONVERT_TO_BINARY')
        )

    def copy_resource(api_client_target, target_api_id, target_resources, source_resources, src_res_id):
        src_res = source_resources[src_res_id]
        path_part = src_res.get('pathPart')
        if path_part:
            parent_id = src_res.get('parentId')
            if parent_id in target_resources:
                try:
                    new_res = api_client_target.create_resource(
                        restApiId=target_api_id,
                        parentId=target_resources[parent_id]['id'],
                        pathPart=path_part
                    )
                    target_resources[src_res_id] = new_res
                    print(f"Created resource {src_res_id} with path {path_part} in target API.")
                except Exception as e:
                    print(f"Failed to create resource {src_res_id} with path {path_part}. Error: {str(e)}")
            else:
                print(f"Parent resource {parent_id} not found in target API for resource {src_res_id}.")
        else:
            target_resources[src_res_id] = target_resources[root_resource_id]

    for src_res_id in source_resources:
        if 'pathPart' not in source_resources[src_res_id]:  # Root resource handling
            target_resources[src_res_id] = target_resources[root_resource_id]
        else:
            copy_resource(api_client_target, target_api_id, target_resources, source_resources, src_res_id)

    for src_res_id, src_res in source_resources.items():
        for method in src_res.get('resourceMethods', {}):
            if src_res_id in target_resources:
                integration_uri = f"arn:aws:apigateway:{target_region}:lambda:path/2015-03-31/functions/{target_lambda_arn}/invocations"
                create_method(api_client_target, target_api_id, target_resources[src_res_id]['id'], method, integration_uri)
                print(f"Created method {method} for resource {src_res_id} in target API.")
            else:
                print(f"Resource {src_res_id} not found in target API for method {method}.")

    return target_api_id

def check_function_exists(lambda_client, function_name):
    try:
        lambda_client.get_function(FunctionName=function_name)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            return False
        else:
            raise e

def lambda_handler(event, context):
    functions = list_lambda_functions(lambda_client_source)
    for function in functions:
        function_name = function['FunctionName']
        function_details = get_lambda_function(lambda_client_source, function_name)
        # Check if function already exists in the target account
        if not check_function_exists(lambda_client_target, function_name):
            create_lambda_function(lambda_client_target, function_details)

            api_triggers = get_api_triggers(lambda_client_source, function_name)
            target_lambda_arn = f"arn:aws:lambda:{target_region}:{account_id}:function:{function_name}"
            for trigger in api_triggers:
                try:
                    source_arn = trigger['Condition']['ArnLike']['AWS:SourceArn']
                    source_api_id = source_arn.split(':')[5].split('/')[0]
                    target_api_id = copy_api(api_client_source, api_client_target, source_api_id, target_lambda_arn)
                    copy_resource_policy(api_client_source, api_client_target, source_api_id, target_api_id)
                    if target_api_id:
                        lambda_client_target.add_permission(
                            FunctionName=function_name,
                            StatementId=f"{function_name}-permission",
                            Action='lambda:InvokeFunction',
                            Principal='apigateway.amazonaws.com',
                            SourceArn=f"arn:aws:execute-api:{target_region}:{account_id}:{target_api_id}//"
                        )
                except Exception as e:
                    print(f"Failed to create trigger {trigger}")
        else:
            print(f"Function {function_name} already exists in target account. Skipping...")
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda functions and triggers copied successfully')
    }


lambda_handler(None, None)
