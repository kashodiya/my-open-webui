import re

def parse_caddyfile(file_path):
    urls = []
    with open(file_path, 'r') as file:
        lines = file.readlines()
        
    for i in range(len(lines) - 1):
        current_line = lines[i].strip()
        next_line = lines[i + 1].strip()
        
        if current_line.startswith('# '):
            port_match = re.match(r':(\d{4})', next_line)
            if port_match:
                text = current_line[2:]  # Remove '# ' from the beginning
                port = port_match.group(1)
                url = f"https://{text}:{port}"
                urls.append(url)
    
    return urls

def main():
    file_path = '/tmp/Caddyfile'
    urls = parse_caddyfile(file_path)
    
    print("Generated URLs:")
    for url in urls:
        print(url)

if __name__ == "__main__":
    main()