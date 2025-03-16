import os
import json
import hashlib
from datetime import datetime, timedelta
import boto3
from botocore.exceptions import ClientError

# Create EC2 client
ec2_client = boto3.client('ec2')
user_pool_name = 'myllm-user-pool'
s3_client = boto3.client('s3')

def get_project_info(parameter_name):
    ssm_client = boto3.client('ssm')
    try:
        response = ssm_client.get_parameter(Name=parameter_name, WithDecryption=True)
        parameter_value = response['Parameter']['Value']
        myowu_info = json.loads(parameter_value)
        print("Successfully retrieved and parsed myowu-info:")
        print(myowu_info)
        return myowu_info
    except ssm_client.exceptions.ParameterNotFound:
        print(f"Parameter {parameter_name} not found")
    except json.JSONDecodeError:
        print("Failed to parse JSON from parameter value")
    except Exception as e:
        print(f"An error occurred: {str(e)}")
    return None

# def generate_token(auth_key):
#     timestamp = datetime.utcnow().timestamp()
#     token = hashlib.sha256(f"{auth_key}{timestamp}".encode()).hexdigest()
#     return token

# def verify_token(token):
#     return True


# Add this at the beginning of your file, after the imports
TOKEN_STORAGE = {}
# Change this to a year in seconds
TOKEN_EXPIRATION = 365 * 24 * 60 * 60  # One year in seconds

def generate_token(auth_key):
    timestamp = datetime.utcnow().timestamp()
    token = hashlib.sha256(f"{auth_key}{timestamp}".encode()).hexdigest()
    expiration = datetime.utcnow() + timedelta(seconds=TOKEN_EXPIRATION)
    TOKEN_STORAGE[token] = expiration
    return token


def verify_token(token):
    if token in TOKEN_STORAGE:
        expiration = TOKEN_STORAGE[token]
        if datetime.utcnow() < expiration:
            return True
        else:
            del TOKEN_STORAGE[token]
    return False


def login_post_handler(event, auth_key):
    body = json.loads(event['body'])
    print(f'Body key: {body.get('key')}')
    print(f'auth_key: {auth_key}')
    if body.get('key') == auth_key:
        token = generate_token(auth_key)
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json',
                'Set-Cookie': f'token={token}; HttpOnly; Secure; SameSite=Strict'
            },
            'body': json.dumps({'token': token})
        }
    else:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': 'Invalid key'})
        }

def hello_get_handler(event):
    return {"statusCode": 200, "body": "Hello there!"}

def controller_get_handler(event):
    with open('index.html', 'r') as file:
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'text/html'},
            'body': file.read()
        }

def default_handler(event):
    with open('login.html', 'r') as file:
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'text/html', 'Access-Control-Allow-Origin': '*'},
            'body': file.read()
        }

def ec2s_get_handler(event):
    try:
        instances = get_ec2_instances()
        response = {
            'statusCode': 200,
            'body': json.dumps(instances),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    return response

def sg_get_handler(event, security_group_id):
    try:
        sg = get_sg(security_group_id)
        security_group_id = sg['GroupId']
        response = {
            'statusCode': 200,
            'body': json.dumps(sg),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    return response

def project_info_get_handler(event, project_info):
    try:
        response = {
            'statusCode': 200,
            'body': project_info,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    return response

def apps_get_handler(event, apps):
    try:
        response = {
            'statusCode': 200,
            'body': apps,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    return response

def get_ec2_instances():
    response = ec2_client.describe_instances()
    instances = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            public_ip = instance.get('PublicIpAddress', 'N/A')
            public_dns = instance.get('PublicDnsName', 'N/A')
            instances.append({
                'InstanceId': instance_id,
                'PublicIP': public_ip,
                'PublicDNS': public_dns
            })
    return instances

def get_sg(security_group_id):
    if security_group_id != 'NONE':
        return security_group_id
    security_group_name = "myllm_allow_sources"
    try:
        response = ec2_client.describe_security_groups(
            Filters=[
                {
                    'Name': 'group-name',
                    'Values': [security_group_name]
                }
            ]
        )
        if len(response['SecurityGroups']) > 0:
            security_group = response['SecurityGroups'][0]
            return security_group
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': f'Security group "{security_group_name}" not found'
                })
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error occurred while fetching security group',
                'error': str(e)
            })
        }

def get_apps(data_bucket_name):
    json_txt = read_file_from_s3(data_bucket_name, 'apps.json')
    print(f'{json_txt}')
    return json_txt

def get_first_data_bucket():
    response = s3_client.list_buckets()
    for bucket in response['Buckets']:
        if '-data-' in bucket['Name']:
            name = bucket['Name']
            print(f'Found data bucket name: {name}')
            return name
    return None

def get_data_bucket_name():
    return get_first_data_bucket()

def read_file_from_s3(bucket_name, file_key):
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
        file_content = response['Body'].read().decode('utf-8')
        return file_content
    except ClientError as e:
        if e.response['Error']['Code'] == "NoSuchKey":
            print(f"The file {file_key} was not found in the bucket {bucket_name}")
        else:
            print(f"An error occurred: {e}")
        return None

def allow_get_handler(event):
    query_params = event.get('queryStringParameters', {})
    allow_ip = query_params.get('ip')    
    ip_range = f'{allow_ip}/32'
    add_ingress_rule(ip_range)
    return {
        'statusCode': 200,
        'body': json.dumps({'result': f'Money transferred'}),
    }

def add_ingress_rule(ip_range):
    sg = get_sg('NONE')
    try:
        response = ec2_client.authorize_security_group_ingress(
            GroupId=sg['GroupId'],
            IpPermissions=[
                {
                    'IpProtocol': 'tcp',
                    'FromPort': 8100,
                    'ToPort': 8199,
                    'IpRanges': [
                        {
                            'CidrIp': ip_range,
                            'Description': 'Allowed via controller'
                        },
                    ],
                },
            ],
        )
        print(f"Ingress rule added successfully: {response}")
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
            print(f"Ingress rule already exists for ports 8100-8199 from {ip_range}")
        else:
            print(f"Error adding ingress rule: {e}")

def get_cognito_client_callback_urls(user_pool_name):
    cognito_client = boto3.client('cognito-idp')
    user_pool_id = None
    response = cognito_client.list_user_pools(MaxResults=60)
    for pool in response['UserPools']:
        if pool['Name'] == user_pool_name:
            user_pool_id = pool['Id']
            break
    if user_pool_id is None:
        raise ValueError(f"User Pool with name '{user_pool_name}' not found")
    response = cognito_client.list_user_pool_clients(UserPoolId=user_pool_id)
    client_ids = [client['ClientId'] for client in response['UserPoolClients']]
    callback_urls = {}
    for client_id in client_ids:
        client_info = cognito_client.describe_user_pool_client(
            UserPoolId=user_pool_id,
            ClientId=client_id
        )
        client_name = client_info['UserPoolClient']['ClientName']
        callback_urls[client_name] = client_info['UserPoolClient'].get('CallbackURLs', [])
    return callback_urls

# Define a dictionary mapping (path, method) tuples to handler functions
HANDLERS = {
    ('/login', 'POST'): login_post_handler,
    ('/index', 'GET'): controller_get_handler,
    ('/ec2s', 'GET'): ec2s_get_handler,
    ('/allow', 'GET'): allow_get_handler,
    ('/sg', 'GET'): sg_get_handler,
    ('/apps', 'GET'): apps_get_handler,
    ('/project-info', 'GET'): project_info_get_handler,
    ('/hello', 'GET'): hello_get_handler
}

def lambda_handler(event, context):
    try:
        function_name = context.function_name
        project_id = function_name.split('-')[0]
        parameter_name = f'/{project_id}/info'
        project_info = get_project_info(parameter_name)
        auth_key = project_info['controller_auth_key']
        apps = project_info['apps'] 
        print(project_info)
        print(auth_key)
        
        data_bucket_name = get_data_bucket_name()
        security_group_id = 'NONE'
        
        # cookies = event.get('headers', {}).get('cookie', '')
        # token = next((c.split('=')[1] for c in cookies.split('; ') if c.startswith('token=')), None)
        cookies = event.get('headers', {}).get('cookie', '')
        token = next((c.split('=')[1] for c in cookies.split('; ') if c.startswith('token=')), None)

        http_method = event['requestContext']['http']['method']
        path = event['rawPath']
        newPath = '/login'
        if path == '/login' or path == '/':
            pass
        else:
            if token:
                # authenticated_paths = ['/ec2s', '/allow', '/sg', '/apps', '/project-info']
                # if path in authenticated_paths:
                if not token or not verify_token(token):
                    return {
                        'statusCode': 401,
                        'headers': {'Content-Type': 'application/json'},
                        'body': json.dumps({'message': 'Invalid or expired token'})
                    }            
                else:
                    newPath = path
        
        handler = HANDLERS.get((newPath, http_method), default_handler)
        
        # Pass the required arguments to the handler functions
        if handler == login_post_handler:
            return handler(event, auth_key)
        elif handler == sg_get_handler:
            return handler(event, security_group_id)
        elif handler == project_info_get_handler:
            return handler(event, project_info)
        elif handler == apps_get_handler:
            return handler(event, apps)
        else:
            return handler(event)
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }