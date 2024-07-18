This reproduction will deploy an Azure VMSS and install Vault.

Update terraform.tfvars with your Vault license, Vault version, etc. to set variables.

ssh to VM using `ssh -i </path/to/private/key> adminuser@<public_ip_address>`

# Export VAULT_ADDR
export VAULT_ADDR=http://127.0.0.1:8200

# Start Vault service
sudo systemctl start vault