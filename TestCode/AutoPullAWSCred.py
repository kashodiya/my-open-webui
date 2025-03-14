import subprocess
import json
import os
import boto3
import time
import configparser
import sys
 
def get_aws_credentials():
    print("Initiating AWS SSO login. Please complete the login process in your browser.")
 
    # Ensure you have sso_profile in ~\.aws\config file
    # [profile sso_profile]
    # sso_start_url = https://stlfrb.awsapps.com/start
    # sso_region = us-east-1
    # region = us-east-1
    # output = json
 
    subprocess.run(["aws", "sso", "login", "--profile", "sso_profile"], check=True)
 
    # mfa_code = input("Please enter your Okta MFA code: ")
    # print(f"MFA code {mfa_code} received. Continuing with the login process...")
    # time.sleep(5)
 
    home = os.path.expanduser("~")
    cache_dir = os.path.join(home, ".aws", "sso", "cache")
   
    cache_files = [f for f in os.listdir(cache_dir) if f.endswith('.json')]
    latest_cache = max(cache_files, key=lambda f: os.path.getmtime(os.path.join(cache_dir, f)))
   
    with open(os.path.join(cache_dir, latest_cache), 'r') as f:
        cached_data = json.load(f)
 
    access_token = cached_data['accessToken']
 
    # List accounts
    sso = boto3.client('sso', region_name='us-east-1')  # Replace with your SSO region
    accounts = sso.list_accounts(accessToken=access_token)    
    # print(accounts)
 
    available_roles = []
    for account in accounts['accountList']:
        # print(f"Account: {account['accountId']} ({account['accountName']})")
       
        # List roles for each account
        roles = sso.list_account_roles(
            accessToken=access_token,
            accountId=account['accountId']
        )
       
        for role in roles['roleList']:
            available_roles.append((account['accountId'], role['roleName']))
 
    profile_names = []
    for account_id, role_name in available_roles:
        credentials = sso.get_role_credentials(
            roleName=role_name,
            accountId=account_id,
            accessToken=access_token
        )['roleCredentials']
 
        if credentials:
            print(f"Got credentials for: Account ID: {account_id},  Role: {role_name}")
            # print(credentials)
            profile_name = f"sso-{account_id}-{role_name}"
            profile_names.append(profile_name)
            update_aws_cli_config(credentials, account_id, role_name, profile_name)
 
    print("")
    print("Direct URLs to the console:")
    print("")
 
    for account_id, role_name in available_roles:
        print(f"https://stlfrb.awsapps.com/start/#/console?account_id={account_id}&role_name={role_name}")
 
    print("")
    print("Cut paste one of folowing to set profile:")
    print("")
 
    for i, option in enumerate(profile_names, start=1):
        print(f"set AWS_DEFAULT_PROFILE={option}")
 
 
    # print("Set active profile:")
    # i = 1
    # for i, option in enumerate(profile_names, start=1):
    #     print(f"{i}. {option}")
    # i = i + 1
    # print(f"{i}. Skip this step.")
 
    # while True:
    #     try:
    #         choice = int(input("Enter the number of your choice: "))
    #         if 1 <= choice <= len(profile_names):
    #             selected_option = profile_names[choice - 1]
    #             print(f"set AWS_PROFILE={selected_option}")
    #             os.environ["AWS_PROFILE"] = selected_option
    #             break
    #         else:
    #             print("Invalid choice. Please enter a number within the range.")
    #     except ValueError:
    #         print("Invalid input. Please enter a number.")
 
 
def update_aws_cli_config(credentials, account_id, role_name, profile_name):
    config = configparser.ConfigParser()
    # config_file = os.path.expanduser("~/.aws/config")
    # credentials_file = os.path.expanduser("~/.aws/credentials")
    aws_foldere = find_aws_folder()
 
    # config_file = r"D:\Users\tony.yang\.aws\config"
    # credentials_file = r"D:\Users\tony.yang\.aws\credentials"
    config_file = os.path.join(aws_foldere, 'config')
    credentials_file = os.path.join(aws_foldere, 'credentials')
 
    print(f"Updating: Config file at: {config_file}")
 
    # Update config file
    if os.path.exists(config_file):
        config.read(config_file)
 
    config[f"profile {profile_name}"] = {
        "region": "us-east-1",  # Replace with your default region
        "output": "json",
        "sso_start_url": "https://stlfrb.awsapps.com/start",
        "sso_region": "us-east-1"
    }
   
    with open(config_file, 'w') as configfile:
        config.write(configfile)
   
    print(f"Updating: Credentials file at: {credentials_file}")
    # Update credentials file
    config = configparser.ConfigParser()
    if os.path.exists(credentials_file):
        config.read(credentials_file)
   
    config[profile_name] = {
        "aws_access_key_id": credentials['accessKeyId'],
        "aws_secret_access_key": credentials['secretAccessKey'],
        "aws_session_token": credentials['sessionToken']
    }
   
    with open(credentials_file, 'w') as configfile:
        config.write(configfile)
   
    print(f"Updated profile: {profile_name}")
 
def find_aws_folder():
    # Get the user's home directory
    home_dir = os.getenv('USERPROFILE') or os.getenv('HOME')
   
    if home_dir:
        aws_folder = os.path.join(home_dir, '.aws')
        if os.path.exists(aws_folder):
            return aws_folder
        else:
            return ""
    else:
        return ""
 
# Get the credentials
try:
    get_aws_credentials()
except Exception as e:
    print(f"An error occurred: {str(e)}")