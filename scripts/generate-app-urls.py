import os
import glob
import json

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

json.dump(processed_data, open('apps.json', 'w'), indent=2)

