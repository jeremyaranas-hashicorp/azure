variable "vault_license" {
  type    = string
  default = ""
}

variable "vault_version" {
  type    = string
  default = ""
}

variable "public_key" {
  type    = string
  default = true
}

variable "instances" {
  type    = string
  default = "1"
}

variable "azure_sub_id" {
  type    = string
  default = ""
}

variable "azure_rg" {
  type    = string
  default = "vmss-rg"
}

variable "azure_vmss" {
  type    = string
  default = "vmss-terraform"
}

variable "azure_tenant_id" {
  type    = string
  default = ""
}

