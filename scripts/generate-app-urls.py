import os
import glob
import json
import boto3
import getpass

# Get the current user
current_user = getpass.getuser()

PROJECT_ID = os.environ.get('PROJECT_ID')
print(f'Generating apps for project: {PROJECT_ID}')

# Get the AWS region from the environment variable
aws_region = os.environ.get('AWS_REGION')

# Initialize the SSM client with the specified region
ssm_client = boto3.client('ssm', region_name=aws_region)


# Initialize the S3 client
# s3 = boto3.client('s3')

def process_caddyfiles(directory):
    result = []
    
    # Get all .Caddyfile files in the specified directory
    caddyfiles = glob.glob(os.path.join(directory, '*.Caddyfile'))
    
    for file_path in caddyfiles:
        with open(file_path, 'r') as file:
            # Read the first two lines
            first_line = file.readline().strip()
            second_line = file.readline().strip()
            
            # Process the first line (name)
            name = first_line[2:] if first_line.startswith('# ') else first_line
            
            # Process the second line (port)
            port = second_line[1:5] if second_line.startswith(':') else second_line
            
            # Get the file name without extension as id
            id = os.path.splitext(os.path.basename(file_path))[0]
            
            # Append the processed data to the result list
            result.append({
                'name': name,
                'port': port,
                'id': id
            })
    
    return result

# Specify the directory path
directory = '/etc/caddy/apps'

# Process the Caddyfiles and get the result
processed_data = process_caddyfiles(directory)

# json.dump(processed_data, open('apps.json', 'w'), indent=2)


# Convert processed_data to a JSON string
json_data = json.dumps(processed_data, indent=2)

# print(json.dumps(processed_data))

# Construct the parameter name
parameter_name = f"/{PROJECT_ID}/apps"

if current_user == 'ubuntu':
    print("The current user is 'ubuntu'.")
    parameter_name = f"/{PROJECT_ID}/appsg"

print(f'Param store key is: {parameter_name}')


# Put the parameter
response = ssm_client.put_parameter(
    Name=parameter_name,
    Value=json_data,
    Type='String',
    Overwrite=True
)

# Print the response (optional)
print(response)

# # Get the S3 bucket name from environment variable
# bucket_name = os.environ.get('DATA_BUCKET_NAME')

# # Check if the bucket name is available
# if not bucket_name:
#     raise ValueError("DATA_BUCKET_NAME environment variable is not set")

# # Create an S3 client
# s3_client = boto3.client('s3')

# # File name
# file_name = 'apps.json'

# try:
#     # Upload the file
#     s3_client.put_object(
#         Bucket=bucket_name,
#         Key=file_name,
#         Body=json_data,
#         ContentType='application/json'
#     )
#     print(f"File {file_name} uploaded successfully to {bucket_name}")
# except Exception as e:
#     print(f"Error uploading file to S3: {str(e)}")
