import re, json

def parse_caddyfile(file_path):
    with open(file_path) as f:
        lines = f.readlines()
    return [{"name": lines[i][2:].strip(), "port": m.group(1)}
            for i, m in enumerate(map(lambda x: re.match(r':(\d{4})', x.strip()), lines[1:]))
            if m and lines[i].strip().startswith('# ')]

if __name__ == "__main__":
    json.dump(parse_caddyfile('Caddyfile'), open('apps.json', 'w'), indent=2)