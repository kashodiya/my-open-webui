param (
    [Parameter(Mandatory=$true)]
    [string]$VPC_ID
)

# Get the VPC CIDR block
$VPC_CIDR = aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].CidrBlock' --output text

if (-not $VPC_CIDR) {
    Write-Error "Unable to find VPC with ID: $VPC_ID"
    exit 1
}

# Get all existing subnet CIDR blocks in the VPC
$EXISTING_SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].CidrBlock' --output text

# Convert VPC CIDR to an array of octets
$VPC_OCTETS = $VPC_CIDR.Split("/")[0].Split(".")

# Start with the first possible IP in the VPC range
$CURRENT_IP = "{0}.{1}.{2}.0" -f $VPC_OCTETS[0], $VPC_OCTETS[1], $VPC_OCTETS[2]

# Loop until we find an available /32 subnet
while ($true) {
    $CANDIDATE_SUBNET = "$CURRENT_IP/32"
    
    # Check if the candidate subnet is within the VPC CIDR and not already in use
    if ($CANDIDATE_SUBNET.StartsWith($VPC_CIDR.Split("/")[0]) -and ($EXISTING_SUBNETS -notcontains $CANDIDATE_SUBNET)) {
        Write-Output "Available /32 subnet: $CANDIDATE_SUBNET"
        break
    }
    
    # Increment the IP address
    $IP_PARTS = $CURRENT_IP.Split(".")
    $IP_PARTS[3] = [int]$IP_PARTS[3] + 1
    $CURRENT_IP = $IP_PARTS -join "."
    
    # Check if we've gone through all possible IPs in the VPC range
    if ($CURRENT_IP -eq "{0}.{1}.{2}.255" -f $VPC_OCTETS[0], $VPC_OCTETS[1], $VPC_OCTETS[2]) {
        Write-Output "No available /32 subnets found in the VPC range."
        exit 1
    }
}