ssh -i %PDIR%keys\main.pem ubuntu@%EC2_IP_GPU% "mkdir -p /home/ubuntu/ansible"
scp -r -i %PDIR%keys\main.pem run-ansible.sh ubuntu@%EC2_IP_GPU%:/home/ubuntu/ansible/run-ansible.sh
