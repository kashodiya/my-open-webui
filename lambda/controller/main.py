import os
import sys
import json
import hashlib
# from datetime import datetime, timedelta
from datetime import datetime, timezone, timedelta
import boto3
from botocore.exceptions import ClientError
from dateutil.relativedelta import relativedelta
# import requests


# Add the /package directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), "package"))

# Now you can import your packages
import jwt


# Create EC2 client
ec2_client = boto3.client('ec2')
user_pool_name = 'myllm-user-pool'
s3_client = boto3.client('s3')
scheduler = boto3.client('scheduler')


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



# Add this at the beginning of your file, after the imports
# TOKEN_STORAGE = {}
# Change this to a year in seconds
# TOKEN_EXPIRATION = 365 * 24 * 60 * 60  # One year in seconds


def generate_token(auth_key, jwt_secret_key):
    print(f"Generating token for auth_key: {auth_key}")
    payload = {
        'auth_key': auth_key,
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, jwt_secret_key, algorithm='HS256')
    print(f"Generated token: {token}")
    return token

def verify_token(token, jwt_secret_key):
    print(f"Verifying token: {token}")
    try:
        payload = jwt.decode(token, jwt_secret_key, algorithms=['HS256'])
        print(f"Token payload: {payload}")
        print("Token is valid")
        return True
    except jwt.ExpiredSignatureError:
        print("Token has expired")
        return False
    except jwt.InvalidTokenError:
        print("Invalid token")
        return False
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        return False


# def generate_token(auth_key, controller_token_bucket):
#     timestamp = datetime.utcnow().timestamp()
#     token = hashlib.sha256(f"{auth_key}{timestamp}".encode()).hexdigest()
#     expiration = int((datetime.utcnow() + timedelta(seconds=TOKEN_EXPIRATION)).timestamp())
    
#     S3_CLIENT.put_object(
#         Bucket=controller_token_bucket,
#         Key=f"tokens/{token}",
#         Body=json.dumps({"expiration": expiration})
#     )
#     return token

# def verify_token(token, controller_token_bucket):
#     print(f"Verifying token: {token}")
#     try:
#         print(f"Attempting to retrieve token data from S3 bucket: {controller_token_bucket}")
#         response = S3_CLIENT.get_object(Bucket=controller_token_bucket, Key=f"tokens/{token}")
#         print("Successfully retrieved token data from S3")
        
#         token_data = json.loads(response['Body'].read().decode('utf-8'))
#         print(f"Token data: {token_data}")
        
#         expiration = token_data['expiration']
#         current_time = datetime.utcnow().timestamp()
#         print(f"Current time: {current_time}, Token expiration: {expiration}")
        
#         if current_time < expiration:
#             print("Token is valid")
#             return True
#         else:
#             print("Token has expired, deleting from S3")
#             S3_CLIENT.delete_object(Bucket=controller_token_bucket, Key=f"tokens/{token}")
#             print("Expired token deleted from S3")
#             return False
#     except S3_CLIENT.exceptions.NoSuchKey:
#         print(f"Token not found in S3: {token}")
#         return False
#     except Exception as e:
#         print(f"An unexpected error occurred: {str(e)}")
#         return False


def login_post_handler(event, auth_key, jwt_secret_key):
    body = json.loads(event['body'])
    print(f'Body key: {body.get('key')}')
    print(f'auth_key: {auth_key}')
    if body.get('key') == auth_key:
        token = generate_token(auth_key, jwt_secret_key)
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
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


def stop_ec2_get_handler(event, instance_id):
    try:
        stop_response = ec2_client.stop_instances(InstanceIds=[instance_id])
        
        # Get the current state of the instance
        instance_state = stop_response['StoppingInstances'][0]['CurrentState']['Name']
        
        response = {
            'statusCode': 200,
            'body': json.dumps({'status': str(instance_state)}),
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



def start_ec2_get_handler(event, instance_id):
    try:
        start_response = ec2_client.start_instances(InstanceIds=[instance_id])

        # Get the current state of the instance
        instance_state = start_response['StartingInstances'][0]['CurrentState']['Name']
        
        response = {
            'statusCode': 200,
            'body': json.dumps({'status': str(instance_state)}),
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



def ec2_status_get_handler(event, instance_id):
    try:
        status = get_ec2_instance_status(instance_id)
        response = {
            'statusCode': 200,
            'body': json.dumps(status),
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

# def get_apps(data_controller_token_bucket):
#     json_txt = read_file_from_s3(data_controller_token_bucket, 'apps.json')
#     print(f'{json_txt}')
#     return json_txt

# def get_first_data_bucket():
#     response = s3_client.list_buckets()
#     for bucket in response['Buckets']:
#         if '-data-' in bucket['Name']:
#             name = bucket['Name']
#             print(f'Found data bucket name: {name}')
#             return name
#     return None

# def get_data_controller_token_bucket():
#     return get_first_data_bucket()


def read_file_from_s3(controller_token_bucket, file_key):
    try:
        response = s3_client.get_object(Bucket=controller_token_bucket, Key=file_key)
        file_content = response['Body'].read().decode('utf-8')
        return file_content
    except ClientError as e:
        if e.response['Error']['Code'] == "NoSuchKey":
            print(f"The file {file_key} was not found in the bucket {controller_token_bucket}")
        else:
            print(f"An error occurred: {e}")
        return None



def allow_get_handler(event, ec2_security_group_id):
    print(f"Event received: {event}")
    print(f"EC2 Security Group ID: {ec2_security_group_id}")

    query_params = event.get('queryStringParameters', {})
    allow_ip = query_params.get('ip')    
    ip_range = f'{allow_ip}/32'
    print(f"IP to allow: {allow_ip}, IP range: {ip_range}")

    try:
        # Describe the security group
        print(f"Describing security group: {ec2_security_group_id}")
        response = ec2_client.describe_security_groups(GroupIds=[ec2_security_group_id])
        print(f"Security group description response: {response}")
        
        # Get the security group
        security_group = response['SecurityGroups'][0]
        print(f"Security group details: {security_group}")
        
        # Find the ingress rule with description "main-range"
        main_range_rule = None
        for rule in security_group['IpPermissions']:
            print(f"Checking rule: {rule}")
            if 'IpRanges' in rule and rule['IpRanges'] and 'Description' in rule['IpRanges'][0] and rule['IpRanges'][0]['Description'] == 'main-range':
                main_range_rule = rule
                print(f"Found main-range rule: {main_range_rule}")
                break
                    
        if main_range_rule:
            # Extract the port information from the main-range rule
            from_port = main_range_rule['FromPort']
            to_port = main_range_rule['ToPort']
            ip_protocol = main_range_rule['IpProtocol']
            print(f"Main range rule details - From Port: {from_port}, To Port: {to_port}, IP Protocol: {ip_protocol}")
            
            # Generate the description with current timestamp
            current_time = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
            new_description = f"added-on-{current_time}" 
            print(f"New rule description: {new_description}")

            # Create a new ingress rule with the same port and new IP range
            print(f"Adding new ingress rule for IP range: {ip_range}")
            ec2_client.authorize_security_group_ingress(
                GroupId=ec2_security_group_id,
                IpPermissions=[
                    {
                        'IpProtocol': ip_protocol,
                        'FromPort': from_port,
                        'ToPort': to_port,
                        'IpRanges': [{'CidrIp': ip_range, 'Description': new_description}]
                    }
                ]
            )
            
            print(f"New ingress rule added successfully with IP range: {ip_range}")
            return {
                'statusCode': 200,
                'body': json.dumps({'result': 'All ok'}),
            }
        else:
            print("No ingress rule found with description 'main-range'")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': 'Not able to find main range',
                    'error': True
                })
            }
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
            print(f"Rule already exists for IP range: {ip_range}")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Already allowed',
                    'error': False
                })
            }
        else:
            print(f"Error occurred: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': 'Allowed',
                    'error': str(e)
                })
            }        
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Failed to transfer money',
                'error': str(e)
            })
        }
    


def ec2_schedular_info_get_handler(event, project_id):
    try:
        start_name = f'{project_id}-start-ec2-schedule'
        stop_name = f'{project_id}-stop-ec2-schedule'

        start_info = get_scheduler_info(start_name)
        stop_info = get_scheduler_info(stop_name)


        response = {
            'statusCode': 200,
            'body': json.dumps({"start": start_info, "stop": stop_info}),
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


def get_scheduler_info(scheduler_name):
    try:
        # Get the scheduler details
        response = scheduler.get_schedule(Name=scheduler_name)
        
        # Extract relevant information
        schedule_expression = response.get('ScheduleExpression', 'N/A')
        state = response.get('State', 'N/A')
        is_disabled = state.lower() == 'disabled'
        
        # Get the target information
        target = response.get('Target', {})
        target_arn = target.get('Arn', 'N/A')
        
        # Print the scheduler information
        print(f"Scheduler Name: {scheduler_name}")
        print(f"Schedule Expression: {schedule_expression}")
        print(f"State: {state}")
        print(f"Is Disabled: {is_disabled}")
        print(f"Target ARN: {target_arn}")

        return {"isDisabled": is_disabled, "time": schedule_expression}
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print(f"Scheduler '{scheduler_name}' not found.")
        else:
            print(f"An error occurred: {e}")

def ensble_disable_start_stop_ec2_schedular_get_handler(event, project_id):
    try:
        query_params = event.get('queryStringParameters', {})
        action = query_params.get('action')    

        start_name = f'{project_id}-start-ec2-schedule'
        stop_name = f'{project_id}-stop-ec2-schedule'

        # Apply action on start and stop scheduler
        toggle_start_stop_ec2_schedule(start_name, action)
        toggle_start_stop_ec2_schedule(stop_name, action)

        response = {
            'statusCode': 200,
            'body': json.dumps({'result': f'EC2 start and stop schdeuler are {action}'}),
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

def toggle_start_stop_ec2_schedule(schedule_name, state):
    try:
        if state == 'DISABLED':
            # Disable the schedule
            response = scheduler.update_schedule(
                Name=schedule_name,
                State='DISABLED'
            )
            print(f"Schedule {schedule_name} has been disabled.")
        elif state == 'ENABLED':
            # Enable the schedule
            response = scheduler.update_schedule(
                Name=schedule_name,
                State='ENABLED'
            )
            print(f"Schedule {schedule_name} has been enabled.")
        else:
            print("Invalid state. Use 'DISABLED' or 'ENABLED'.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

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

# def get_token_from_event(event, context):
#     """Extract the token from the Lambda event"""
#     print("Attempting to extract token from event")

#     # Check Authorization header
#     headers = event.get('headers', {})
#     auth_header = headers.get('Authorization') or headers.get('authorization')
#     if auth_header:
#         print("Found Authorization header")
#         parts = auth_header.split()
#         if parts[0].lower() == 'bearer' and len(parts) == 2:
#             print("Bearer token found in Authorization header")
#             return parts[1]

#     # Check query parameters
#     query_params = event.get('queryStringParameters', {})
#     if query_params:
#         token = query_params.get('token')
#         if token:
#             print("Token found in query parameters")
#             return token

#     # Check form data or JSON body
#     body = event.get('body')
#     if body:
#         # Try to parse as JSON
#         try:
#             body_json = json.loads(body)
#             token = body_json.get('token')
#             if token:
#                 print("Token found in JSON body")
#                 return token
#         except json.JSONDecodeError:
#             # If not JSON, treat as form data
#             form_data = parse_qs(body)
#             token = form_data.get('token', [None])[0]
#             if token:
#                 print("Token found in form data")
#                 return token

#     print("No token found in event")
#     return None

def logout_get_handler(event):
    # Set up the response object
    response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # Adjust this for your CORS settings
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': json.dumps({'message': 'Logged out successfully'}),
        'isBase64Encoded': False
    }

    # Set the cookie to expire
    expires = datetime.utcnow() - timedelta(days=1)
    expires_str = expires.strftime("%a, %d %b %Y %H:%M:%S GMT")

    # Add the Set-Cookie header to clear the token
    response['headers']['Set-Cookie'] = f'token=; path=/; expires={expires_str}; Secure; HttpOnly; SameSite=Strict'

    return response

def calculate_time_elapsed(ended_str):
    # Parse the ended timestamp
    ended = datetime.strptime(ended_str, "%Y-%m-%d %H:%M:%S")
    
    # Set the timezone to US/Eastern (for us-east-1)
    eastern = timezone(timedelta(hours=-5))  # EST is UTC-5
    ended = ended.replace(tzinfo=eastern)
    
    # Get the current time in US/Eastern timezone
    now = datetime.now(eastern)
    
    # Calculate the time difference
    time_elapsed = now - ended
    
    # Convert time difference to days, hours, minutes, and seconds
    days = time_elapsed.days
    hours, remainder = divmod(time_elapsed.seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    
    # Prepare the response
    # response = {
    #     "time_elapsed": {
    #         "days": days,
    #         "hours": hours,
    #         "minutes": minutes,
    #         "seconds": seconds
    #     }
    # }
    
    # return response

    parts = []
    if days > 0:
        parts.append(f"{days} day{'s' if days != 1 else ''}")
    if hours > 0:
        parts.append(f"{hours} hour{'s' if hours != 1 else ''}")
    if minutes > 0:
        parts.append(f"{minutes} minute{'s' if minutes != 1 else ''}")
    if seconds > 0 or not parts:  # Always include seconds if no other units or if it's the only non-zero value
        parts.append(f"{seconds} second{'s' if seconds != 1 else ''}")

    if len(parts) == 1:
        return parts[0]
    elif len(parts) == 2:
        return f"{parts[0]} and {parts[1]}"
    else:
        return ", ".join(parts[:-1]) + f", and {parts[-1]}"

def get_s3_file_age(bucket_name, file_name):
    # Create an S3 client
    s3_client = boto3.client('s3')

    try:
        # Get the file's metadata
        response = s3_client.head_object(Bucket=bucket_name, Key=file_name)
        
        # Extract the last modified timestamp
        last_modified = response['LastModified']
        
        # Calculate the time difference
        current_time = datetime.now(last_modified.tzinfo)
        time_difference = relativedelta(current_time, last_modified)
        
        # Construct a human-readable string
        age_parts = []
        if time_difference.years > 0:
            age_parts.append(f"{time_difference.years} year{'s' if time_difference.years > 1 else ''}")
        if time_difference.months > 0:
            age_parts.append(f"{time_difference.months} month{'s' if time_difference.months > 1 else ''}")
        if time_difference.days > 0:
            age_parts.append(f"{time_difference.days} day{'s' if time_difference.days > 1 else ''}")
        if time_difference.hours > 0:
            age_parts.append(f"{time_difference.hours} hour{'s' if time_difference.hours > 1 else ''}")
        if time_difference.minutes > 0:
            age_parts.append(f"{time_difference.minutes} minute{'s' if time_difference.minutes > 1 else ''}")
        if time_difference.seconds > 0:
            age_parts.append(f"{time_difference.seconds} second{'s' if time_difference.seconds > 1 else ''}")
        
        if not age_parts:
            return "Just now"
        
        return ", ".join(age_parts) + " ago", time_difference
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return None, None

def get_ec2_instance_status(instance_id):
    """
    Returns the status of an EC2 instance given its ID.
    
    :param instance_id: The ID of the EC2 instance
    :return: The status of the instance, or None if the instance is not found
    """
    # Create an EC2 client
    ec2 = boto3.client('ec2')
    
    try:
        # Describe the instance
        response = ec2.describe_instances(InstanceIds=[instance_id])
        
        # Check if the instance exists
        if len(response['Reservations']) > 0 and len(response['Reservations'][0]['Instances']) > 0:
            # Get the instance status
            instance = response['Reservations'][0]['Instances'][0]
            return instance['State']['Name']
        else:
            print(f"Instance with ID {instance_id} not found.")
            return None
    
    except ClientError as e:
        print(f"An error occurred: {e}")
        return None

def ec2_setup_status_get_handler(event, bucket_name, project_id):
    try:
        ended = None
        ended_minutes = 0
        ended_hours = 0
        status = ""
        started, time_difference = get_s3_file_age(bucket_name, f'{project_id}-ec2-setup-started')
        if not started:
            status = "EC2 setup is not yet staarted."
        else:
            status = f'Setup started since: {started}.'
            print(f'started => {started}, elapsed => {started}')
            ended, time_difference = get_s3_file_age(bucket_name, f'{project_id}-ec2-setup-ended')
            if not ended:
                print(f'ended => {ended}')
            else:
                ended_minutes = time_difference.minutes
                # ended_hours = time_difference.hours
                ended_hours = getattr(time_difference, 'hours', 0)
                status = f'Setup ended since: {ended}.'
                print(f'ended => {ended}, elapsed => {ended}')
        response = {
            'statusCode': 200,
            'body': json.dumps({'started': started, 'ended': ended, 'status': status, 'endedMinutes': ended_minutes, 'endedHours': ended_hours}),
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

# def call_server_tool():
#     url = "http://ec2-44-213-29-205.compute-1.amazonaws.com:7100/"
    
#     try:
#         # Send a GET request to the URL
#         response = requests.get(url)
        
#         # Check if the request was successful
#         if response.status_code == 200:
#             print("Request successful!")
#             print("Response content:")
#             print(response.text)
#         else:
#             print(f"Request failed with status code: {response.status_code}")
    
#     except requests.exceptions.RequestException as e:
#         print(f"An error occurred: {e}")

def getInstanceIdByIndex(event, project_info):
    query_params = event.get('queryStringParameters', {})
    index = int(query_params['index'])
    if index == 0:
        return project_info['instanceId']
    else:
        return project_info['instanceIdG']


# Define a dictionary mapping (path, method) tuples to handler functions
HANDLERS = {
    ('/login', 'POST'): login_post_handler,
    ('/index', 'GET'): controller_get_handler,
    ('/ec2s', 'GET'): ec2s_get_handler,
    ('/allow', 'GET'): allow_get_handler,
    ('/sg', 'GET'): sg_get_handler,
    ('/apps', 'GET'): apps_get_handler,
    ('/project-info', 'GET'): project_info_get_handler,
    ('/ec2-setup-status', 'GET'): ec2_setup_status_get_handler,
    ('/logout', 'GET'): logout_get_handler,
    ('/start-ec2', 'GET'): start_ec2_get_handler,
    ('/stop-ec2', 'GET'): stop_ec2_get_handler,
    ('/ec2_status', 'GET'): ec2_status_get_handler,
    ('/ec2-schedular-info', 'GET'): ec2_schedular_info_get_handler,
    ('/ensble-disable-start-stop-ec2-schedular', 'GET'): ensble_disable_start_stop_ec2_schedular_get_handler,
    ('/hello', 'GET'): hello_get_handler
}
S3_CLIENT = boto3.client('s3')

def parse_cookies(cookie_string):
    def split_pair(pair):
        if '=' in pair:
            return pair.split('=', 1)
        else:
            return pair, ''  # or you could use (pair, None)

    return {k: v for k, v in (split_pair(pair) for pair in cookie_string.split('; '))}

def lambda_handler(event, context):
    try:
        # call_server_tool()
        function_name = context.function_name
        project_id = function_name.split('-')[0]
        parameter_name = f'/{project_id}/info'
        project_info = get_project_info(parameter_name)
        apps = get_project_info(f'/{project_id}/apps')
        project_info['apps'] = apps

        # Remove keys
        keys_to_remove = ['controller_jwt_secret_key', 'controller_auth_key', 'bedrockGatewayApiKey', 'codeServerPassword', 'jupyterLabToken', 'liteLLMApiKey', 'serverToolPassword', 'serverToolJwtSecret']  # Replace with the actual keys you want to remove
        safe_project_info = {k: v for k, v in project_info.items() if k not in keys_to_remove}
        auth_key = project_info['controller_auth_key']
        # controller_token_bucket = project_info['controller_token_bucket']
        # TODO: Generate it in tf and read from info
        jwt_secret_key = project_info['controller_jwt_secret_key']

        # apps = project_info['apps'] 
        print(project_info)
        print(auth_key)
        
        # data_controller_token_bucket = get_data_controller_token_bucket()
        security_group_id = 'NONE'
        
        # cookies = event.get('headers', {}).get('cookie', '')
        # token = next((c.split('=')[1] for c in cookies.split('; ') if c.startswith('token=')), None)
        # cookies = event.get('headers', {}).get('cookie', '')
        # token = next((c.split('=')[1] for c in cookies.split('; ') if c.startswith('token=')), None)

        # token = get_token_from_event(event, context)

        # Extract cookies from the event
        cookies = event.get('headers', {}).get('cookie', '')

        print(f'cookies = {cookies}')
        # Parse cookies
        cookie_dict = parse_cookies(cookies)
        # Extract the auth token
        token = cookie_dict.get('token')

        http_method = event['requestContext']['http']['method']
        path = event['rawPath']
        newPath = '/login'
        if path == '/login' or path == '/':
            pass
        else:
            if token:
                # authenticated_paths = ['/ec2s', '/allow', '/sg', '/apps', '/project-info']
                # if path in authenticated_paths:
                print(f'Verifying token: {token}')
                if not verify_token(token, jwt_secret_key):
                    return {
                        'statusCode': 401,
                        'headers': {'Content-Type': 'application/json'},
                        'body': json.dumps({'message': 'Invalid or expired token'})
                    }            
                else:
                    newPath = path
            else:
                print('Token not found!')
        
        handler = HANDLERS.get((newPath, http_method), default_handler)

        print(f'Handling path: {newPath}, old path was {path}')
        
        # Pass the required arguments to the handler functions
        if handler == login_post_handler:
            return handler(event, auth_key, jwt_secret_key)
        elif handler == sg_get_handler:
            return handler(event, security_group_id)
        elif handler == project_info_get_handler:
            return handler(event, safe_project_info)
        elif handler == apps_get_handler:
            return handler(event, apps)
        elif handler == allow_get_handler:
            ec2_security_group_id = project_info['ec2SecurityGroupId'] 
            return handler(event, ec2_security_group_id)
        elif handler == start_ec2_get_handler:
            # instance_id = project_info['instanceId']
            instance_id = getInstanceIdByIndex(event, project_info) 
            return handler(event, instance_id)
        elif handler == stop_ec2_get_handler:
            # instance_id = project_info['instanceId'] 
            instance_id = getInstanceIdByIndex(event, project_info) 
            return handler(event, instance_id)
        elif handler == ec2_status_get_handler:
            # instance_id = project_info['instanceId'] 
            instance_id = getInstanceIdByIndex(event, project_info) 
            return handler(event, instance_id)
        elif handler == ensble_disable_start_stop_ec2_schedular_get_handler:
            return handler(event, project_id)
        elif handler == ec2_schedular_info_get_handler:
            return handler(event, project_id)
        elif handler == ec2_setup_status_get_handler:
            return handler(event, project_info['dataBucketName'], project_id)
        else:
            return handler(event)
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }