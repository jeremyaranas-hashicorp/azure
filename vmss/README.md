This reproduction will deploy an Azure Virtual Machine Scale Set (VMSS) and install Vault.

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

# Azure tenant ID
azure_tenant_id = "<tenant_id>"
```

# Wishlist

* Auto-unseal using Azure
* Auto-join

# Azure Access

* Developer access is required to perform certain activities in Azure, for example, creating an App registration. 
* Use this [link](https://doormat.hashicorp.services/azure/tenant/access/request), click on Azure Active Directory Access - hashicorp02, and click on the + sign for Azure AD Developer Access (hashicorp02) to get access

# How to Setup Auto-join Manually (to be added to Terraform)

1. Create an app registration (service principal)
   1. Go to *App registrations* -> *New registration*
   2. Example name: `azure-terraform-vmss-ar`
   3. Select *Single tenant* 
   4. Click *Register*
2. Create a client secret for the service principal
   1. From the app registration *Overview* page, click *Add a certificate or secret*
   2. Click on *New client secret*
   3. Example name: `azure-vmss-cs`
   4. Click *Add*
3. Save the client secret (secret access key)
    2. Add to auto-join config `secret_access_key=<your_secret>`
4. From the *Overview* page, save the application (client) ID
   1. Add to auto-join config `client_id=<your_id>`
5. Update auto-join config to add subscription_id
6. Auto-join config example

```
auto_join = "provider=azure subscription_id=<sub_id> tenant_id=<tenant_id> resource_group=vmss-rg vm_scale_set=vmss-terraform secret_access_key=<secret> client_id=<client_id>"
auto_join_scheme = "http"
```

6. Set permissions
   1. Go to the VMSS -> *Access Control (IAM)* -> *Add a role assignment* -> *Privileged administrator roles* -> *Owner* -> *Next* ->  *Select members* -> add service principal -> *Select* -> *Next* -> *Allow user to assign all roles (highly privileged)* -> *Next* ->  *Review + assign*
   2. From the VMSS, *Instances* -> for each instance, click on the instance -> expand the *Networking* menu - > *Network settings* -> click on the network interface to open the network interface -> *Access control (IAM)* -> *Add a role assignment* -> *Privileged administrator roles* -> *Owner* -> *Next* -> *Select members* -> add service principal -> *Select* -> *Next* -> *Allow user to assign all roles (highly privileged)* -> *Next* -> *Review + assign*
7. Proceed with initializing Vault