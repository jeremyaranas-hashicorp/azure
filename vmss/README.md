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
2. Update the `terraform.tfvars` file with your Vault license, Vault version, etc. to set the variables
3. Run Terraform
   1. `terraform init`
   2. `terraform plan`
   3. `terraform apply --auto-approve`
4. `ssh` to VM using `ssh -i </path/to/private/key> adminuser@<public_ip_address>`
5. Export `VAULT_ADDR`
   `export VAULT_ADDR=http://127.0.0.1:8200`
6. Start Vault service
   1. `sudo systemctl start vault`