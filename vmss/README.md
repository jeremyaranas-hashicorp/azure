This reproduction will deploy an Azure Virtual Machine Scale Set (VMSS) and install Vault with auto-join and auto-unseal.

# Instructions

1. Create Azure subscription
    1. In Doormat, go to Accounts -> Azure -> Create Temporary Subscription 
       1. Tenant ID should be `237fbc04-c52a-458b-af97-eaf7157c0cd4`
 2. From the terminal, authenticate with Azure to configure Terraform to run against the Azure subscription 
       1. `az login`
 3. A new window browser window will open
    1. Click Sign-in options
    2. Click Sign in to an organization
       1. Enter `hashicorp02.onmicrosoft.com`
    3. Select your account
 4. Request developer access using this [link](https://doormat.hashicorp.services/azure/tenant/access/request)
    1. Click on Azure Active Directory Access - hashicorp02
    2. Click on the + sign for Azure AD Developer Access (hashicorp02)

Once your Azure account has been setup with developer access, proceed with the following.

1. Create a `terraform.tfvars` to set variables for your environment (see example)
2. Run Terraform
   1. `terraform init`
   2. `terraform plan`
   3. `terraform apply --auto-approve`
3. Run `az vmss list-instance-public-ips --resource-group vmss-rg --name vmss-terraform --output table` to retrieve public IP addresses of the node(s)
4. `ssh` to VM(s) using `ssh -i </path/to/private/key> azure-user@<public_ip_address>`
5. Export `VAULT_ADDR` on each node
   `export VAULT_ADDR=http://127.0.0.1:8200`
6. Start Vault service on the first node
   1. `sudo systemctl start vault`
7. Initialize Vault on the first node
   1. `vault operator init -format=json > init.json`
8.  Login to Vault on the first node
   1. `vault login $(jq -r .root_token init.json)`
9.  Start Vault service on each additional node
   1.  `sudo systemctl start vault`

To cleanup the environment, run a `terraform destroy`

# Example terraform.tfvars file

```
vault_license = "<your_license>"
vault_version = "1.16.2+ent"
public_key = "<your_public_key>"
instances = "3"
azure_tenant_id = "237fbc04-c52a-458b-af97-eaf7157c0cd4"
key_name = "azure-auto-unseal-key"
```