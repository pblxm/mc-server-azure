## Dockerized Minecraft Server in Azure with monitorization
Dockerized Minecraft server monitored with Prometheus and Grafana

Deployed in Azure with Terraform

Configured with Ansible 

Defined with Docker Compose

## How to deploy
You need to be logged in Azure CLI
Execute `deploy.sh` script

## Optional
Install Terraform, Ansible, Docker and Azure CLI with `install.sh` script

Azure CLI login with: `read -sp "Azure password: " AZ_PASS && az login -u <ACCOUNT> -p $AZ_PASS`