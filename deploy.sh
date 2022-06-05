#!/bin/bash

# Set paths to Terraform and Ansible directories
terraform="./terraform"
ansible="./ansible"

# Name of the SSH key we want to use to connect to the server
keyName="mykey"

# Create enviroment file for the docker compose
echo "HOME=$HOME" > $ansible/.env

# Permissions
chown -R "$USER" .
chmod 744 -R . 

# Initialize terraform project
cd $terraform || exit; terraform init -upgrade &>/dev/null

# Select
read -r -p "Choose plan (1), apply (2) or destroy (3) = " choice

if [[ $choice == 1 ]]; then
	terraform plan
elif [[ $choice == 2 ]]; then
	# Deploy Terraform
	terraform apply

	# Create hosts file
	echo "[nodes]" > "$ansible/hosts"

	# Add server IP from Terraform output
	< ip.txt tr '\n' ' ' >> "$ansible/hosts"

	# Configuration arguments
	echo -n " ansible_user=pbl ansible_connection=ssh ansible_private_key_file=$HOME/.ssh/$keyName\ 
	ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> "$ansible/hosts"

	# Run Ansible playbook
	cd $ansible || exit; ansible-playbook mcserver.yml

elif [[ $choice == 3 ]]; then
	terraform destroy
else
	exit 1
fi
