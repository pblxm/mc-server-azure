#!/bin/bash

# Set admin username
adminUser="pbl"

# Generate SSH key we will to use to connect to the server
keyName="mykey"
test -f "$HOME/.ssh/$keyName" || ssh-keygen -t rsa -f "$HOME/.ssh/$keyName" -q -P ""

# Set paths to Terraform and Ansible directories
terraform="$PWD/terraform"
ansible="$PWD/ansible"

# Generate certificate and private key for Grafana
certs="$ansible/compose/certs/"

test -d "$certs" || ( mkdir "$certs" && openssl req -x509 -sha256 -nodes -days 365 \
					-newkey rsa:2048 -keyout "$certs/mcserver.key" -out "$certs/mcserver.crt" \
					-subj "/C=ES/O=Mc/OU=Mc/CN=myserver.com" )  &>/dev/null

# Create Ansible logs folder
test -d "$ansible/logs" || mkdir "$ansible/logs"

# Create enviroment file for the docker compose
echo "HOME=$HOME" > "$ansible/.env"

# Permissions
chown -R "$USER" .
chmod 744 -R . 

# Initialize terraform project
cd "$terraform" || exit; terraform init -upgrade &>/dev/null

# Selection
read -r -p "Choose plan (1), apply (2) or destroy (3) = " choice

if [[ $choice == 1 ]]; then
	terraform plan
elif [[ $choice == 2 ]]; then
	# Deploy Terraform
	terraform apply -auto-approve -var "admin=$adminUser"

	# Create hosts file
	echo "[nodes]" > "$ansible/hosts"

	# Add server IP from Terraform output
	terraform output -raw server_ip | tr '\n' ' ' >> "$ansible/hosts"

	# Configuration arguments
	echo -n " ansible_user=$adminUser ansible_connection=ssh ansible_private_key_file=$HOME/.ssh/$keyName ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> "$ansible/hosts"

	# Wait for server to be accessible with SSH
	until ssh -l "$adminUser"  -o StrictHostKeyChecking=no -i "$HOME/.ssh/$keyName" "$(terraform output -raw server_ip)" "exit" &> /dev/null; do sleep 3; done

	# Run Ansible playbook
	cd "$ansible" || exit; ansible-playbook mcserver.yml

elif [[ $choice == 3 ]]; then
	terraform destroy
else
	exit 1
fi