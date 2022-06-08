## Dockerized Minecraft Server in Azure with monitorization
Dockerized Minecraft server monitored with Prometheus and Grafana

Deployed in Azure with Terraform

Configured with Ansible 

Defined with Docker Compose

DDNS with DuckDNS

## How to deploy
You need to be logged in Azure CLI

Execute `deploy.sh` script

## Optional
Set your DuckDNS subdomain token inside `./ansible/docker/compose/docker-compose.yml`

Install Terraform, Ansible, Docker and Azure CLI with `install.sh`

Azure CLI login with: `read -sp "Azure password: " AZ_PASS && az login -u <ACCOUNT> -p $AZ_PASS`

Change name for the key or admin user inside `deploy.sh` 