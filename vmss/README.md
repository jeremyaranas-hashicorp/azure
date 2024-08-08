This reproduction will deploy an Azure VMSS and install Vault.

# Instructions

1. Create Azure subscription
    1. In Doormat, go to Accounts -> Azure -> Create Temporary Subscription 
       1. Tenant ID should be `237fbc04-c52a-458b-af97-eaf7157c0cd4`
    2. Login using `az` command line to configure Terraform to run against Azure subscription 
       1. `az login`
       2. Click Sign-in options
       3. Click Sign in to an organization
       4. Enter `hashicorp02.onmicrosoft.com`
       5. Select your account
2. Create a `terraform.tfvars` to set variables for your environment (see example)
3. Run Terraform
   1. `terraform init`
   2. `terraform plan`
   3. `terraform apply --auto-approve`
4. Run `az vmss list-instance-public-ips --resource-group vmss-rg --name vmss-terraform --output table` to retrieve public IP addresses of the node(s)
4. `ssh` to VM using `ssh -i </path/to/private/key> azure-user@<public_ip_address>`
5. Export `VAULT_ADDR`
   `export VAULT_ADDR=http://127.0.0.1:8200`
6. Start Vault service
   1. `sudo systemctl start vault`
7. Initialize Vault
   1. `vault operator init -format=json -key-shares=1 -key-threshold=1 > init.json`
8. Unseal Vault
   1. `vault operator unseal $(jq -r .unseal_keys_hex[0] init.json)`
9. Login to Vault
   1. `vault login $(jq -r .root_token init.json)`


To cleanup the environment, run a `terraform destroy`

# Example terraform.tfvars file

```
# Your Vault license
vault_license = "<your_vault_license>"

# The version of Vault to install
vault_version = "1.16.2+ent"

# Your SSH public key to be able to ssh to server
public_key = "<your_public_key_for_ssh>"

# The number of nodes to deploy in the scale set
instances = "3"
```

# Wishlist

* Auto-unseal using Azure