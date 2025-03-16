import os
import json
import hashlib
from datetime import datetime, timedelta
import boto3
from botocore.exceptions import ClientError

# Get the AUTH_KEY from environment variables
auth_key = os.environ.get('AUTH_KEY')
data_bucket_name = os.environ.get('DATA_BUCKET_NAME')

# auth_key = "123123"

# Create EC2 client
ec2_client = boto3.client('ec2')
user_pool_name = 'myllm-user-pool'
security_group_id = 'NONE'
s3_client = boto3.client('s3')
# data_bucket_name = ''

def generate_token():
    # Generate a simple token using the current timestamp and AUTH_KEY
    timestamp = datetime.utcnow().timestamp()
    token = hashlib.sha256(f"{auth_key}{timestamp}".encode()).hexdigest()
    return token

def verify_token(token):
    # In this simple implementation, we'll consider all tokens valid
    # You might want to implement some basic validation logic here
    return True

def login_post_handler(event):
    body = json.loads(event['body'])
    if body.get('key') == auth_key:
        token = generate_token()
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
    # User info retrieval logic here
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
    # If not authenticated or invalid token, return login.html
    with open('login.html', 'r') as file:
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'text/html', 'Access-Control-Allow-Origin': '*'},
            'body': file.read()
        }

def ec2s_get_handler(event):
    try:
        # Call the function to get EC2 instances
        instances = get_ec2_instances()
        
        # Prepare the response
        response = {
            'statusCode': 200,
            'body': json.dumps(instances),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # For CORS support
            }
        }
    except Exception as e:
        # If an error occurs, return an error response
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # For CORS support
            }
        }
    
    return response    

def sg_get_handler(event):
    try:
        # Call the function to get EC2 instances
        sg = get_sg()
        security_group_id = sg['GroupId']
        
        # Prepare the response
        response = {
            'statusCode': 200,
            'body': json.dumps(sg),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # For CORS support
            }
        }
    except Exception as e:
        # If an error occurs, return an error response
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # For CORS support
            }
        }
    
    return response    

def apps_get_handler(event):
    try:
        # Call the function to get EC2 instances
        apps = get_apps()
        
        # Prepare the response
        response = {
            'statusCode': 200,
            'body': apps,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # For CORS support
            }
        }
    except Exception as e:
        # If an error occurs, return an error response
        response = {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # For CORS support
            }
        }
    
    return response   

def get_ec2_instances():
    
    # Describe EC2 instances
    response = ec2_client.describe_instances()
    
    # Initialize list to store instance information
    instances = []
    
    # Iterate through reservations and instances
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            public_ip = instance.get('PublicIpAddress', 'N/A')
            public_dns = instance.get('PublicDnsName', 'N/A')
            
            # Add instance information to the list
            instances.append({
                'InstanceId': instance_id,
                'PublicIP': public_ip,
                'PublicDNS': public_dns
            })
    
    return instances

def get_sg():
    if security_group_id != 'NONE':
        return security_group_id
    # Security group name to search for
    security_group_name = "myllm_allow_sources"
    
    try:
        # Describe security groups with the specified name
        response = ec2_client.describe_security_groups(
            Filters=[
                {
                    'Name': 'group-name',
                    'Values': [security_group_name]
                }
            ]
        )
        
        # Check if any security groups were found
        if len(response['SecurityGroups']) > 0:
            # Get the first (and should be only) security group
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

def get_apps():
    # name = get_data_bucket_name()
    # if not name:
    #     return '[]'
    # else:
    global data_bucket_name  # Declare the variable as global
    json_txt = read_file_from_s3(data_bucket_name, 'apps.json')
    print(f'{json_txt}')
    return json_txt

# def get_apps():
#     callback_urls = get_cognito_client_callback_urls(user_pool_name)
#     urls = []
#     for key, value in callback_urls.items():
#         for url_string in value:
#             if 'ec2-' in url_string:
#                 just_url = url_string.replace('/oauth2/callback', '')
#                 just_url = just_url.replace('/oauth2/idpresponse', '')      
#                 urls.append({'name': key, 'href': just_url, 'logout_href': f'{just_url}/oauth2/sign_out'})
#     urls.sort(key=lambda x: x['name'])
#     return urls

def get_first_data_bucket():
    response = s3_client.list_buckets()
    
    for bucket in response['Buckets']:
        if '-data-' in bucket['Name']:
            name = bucket['Name']
            print(f'Found data bucket name: {name}')
            return name
    
    
    return None  # Return None if no matching bucket is found

def get_data_bucket_name():
    global data_bucket_name  # Declare the variable as global
    if data_bucket_name == '':
        data_bucket_name = get_first_data_bucket()

    return data_bucket_name


def read_file_from_s3(bucket_name, file_key):
    # Create an S3 client with specified region
    # s3 = boto3.client('s3', region_name=region_name)
    # s3 = boto3.client('s3')
    
    try:
        # Get the object from the bucket
        response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
        
        # Read the file contents
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
    ip_range = f'{allow_ip}/32'  # This allows access from any IP. Adjust as needed for your security requirements.
    add_ingress_rule(ip_range)
    return {
        'statusCode': 200,
        'body': json.dumps({'result': f'Money transferred'}),
    }

def add_ingress_rule(ip_range):
    sg = get_sg()
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
    # Create a Cognito Identity Provider client
    cognito_client = boto3.client('cognito-idp')
    # Find the User Pool ID based on the name
    user_pool_id = None
    response = cognito_client.list_user_pools(MaxResults=60)
    for pool in response['UserPools']:
        if pool['Name'] == user_pool_name:
            user_pool_id = pool['Id']
            break
    # If the user pool is not found, raise an exception
    if user_pool_id is None:
        raise ValueError(f"User Pool with name '{user_pool_name}' not found")
    # List all client apps in the user pool
    response = cognito_client.list_user_pool_clients(UserPoolId=user_pool_id)
    client_ids = [client['ClientId'] for client in response['UserPoolClients']]
    # Get details for each client app
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
    ('/hello', 'GET'): hello_get_handler
}

def lambda_handler(event, context):
    try:
        # Check if the request has a token in the cookie
        cookies = event.get('headers', {}).get('cookie', '')
        token = next((c.split('=')[1] for c in cookies.split('; ') if c.startswith('token=')), None)
        
        if token:
            if verify_token(token):
                # Token is valid, proceed with the request
                pass
            else:
                return {
                    'statusCode': 401,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'message': 'Invalid token'})
                }
        
        http_method = event['requestContext']['http']['method']
        path = event['rawPath']
        
        # Get the appropriate handler based on the path and method, or use the default handler
        handler = HANDLERS.get((path, http_method), default_handler)
        
        return handler(event)        
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }