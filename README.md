# Multiple Azure Virtual Machines with one command 

## Background
Based on an small Proof of Concept to make multiple virtual machines for bigger test, the following generic script was created

The end result of the Terraform script as many virtual machine as configure in locals.tf
The vm has already MongoDB client tools installed.

## Prerequisites:
* Authenticate into Azure via CLI with:  az login
* Have Terraform 0.13+ installed
* Run: terraform init 

```
Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "azurerm" (hashicorp/azurerm) 2.1.0...
```

## Config:
* Set up credential, as in section: "Configure Script - Credentials"
* Change basic parameters, as in file : locals.tf
* Run: terraform apply

## Todo:
* Test with terrafrom 14. 

## Basic Terraform resources in script
* azurerm_resource_group, create a Azure resource group to hold vnet and other resources
* azurerm_virtual_network, create a Azure Virtual Network to peer into
* azurerm_private_endpoint, creates the endpoint in Azure

## In order to provision a Atlas cluster and an Azure VM:
* azurerm_subnet, 
* azurerm_public_ip,
* azurerm_network_security_group,
* azurerm_network_interface,
* azurerm_linux_virtual_machine,

 
## Configure Script - Credentials: "variables.tf"

To configure the provider:  Azure, one needs credentials to gain access.

An Azure subscription is required.  The primary attributes are also expected 
as environment variables. Values need to be provided in TF_VAR_ format.

* TF_VAR_azure_subscription_id=<SUBSCRIPTION_ID>
* TF_VAR_azure_tenant_id=<DIRECTORY_ID>

Third there are several other parameters that are trusted, which should be provided via environment variables.
```

variable "azure_subscription_id" {
  description = "Azure subscription for peering with ..."
  type = string
}

variable "azure_tenant_id" {
  description = "Azure subscription Directory ID"
  type = string
}

variable "public_key_path" {
  description = "Access path to public key"
  type = string
}

variable "private_key_path" {
  description = "Access path to private key"
  type = string
}

variable "admin_password" {
  description = "Generic password for demo resources"
  type = string
}

variable "source_ip" {
  description = "Limit vm access to this ip_address"
  type = string
}
```

## Other configuration: "locals.tf"

In the locals resource of the locals.tf file, several parameters should be adapted to your needs
```
locals {
  # New empty Atlas project name to create in organization
  project_id            = "Multiple-project"
  # A Azure resource group
  resource_group_name   = "Multiple-demo-vms"
  # Associated Azure vnet
  vnet_name             = "Multiple-vnet-vms"
  # Azure location
  location              = "West Europe"
  # Azure alt location (ips and sec groups use this)
  location_alt          = "westeurope"
  # Azure cidr block for vnet
  address_space         = ["10.11.4.0/23"]
  # Azure subnet in vnet
  subnet                = "subnet1"
  # Azure subnet cidr
  subnet_address_space  = "10.11.4.192/26"
  # Atlas & Azure vm user_name
  admin_username        = "demouser1"
  # Azure vm size
  azure_vm_size		      = "Standard_F2"
  # Azure vm_name	
  azure_vm_name		      = "demo"
  # Azure vm_count
  azure_vm_count	      = 2
}
 
terraform {
  required_version = ">= 0.13.2"
}
```


## Give it a go

In you favorite shell, run terraform apply and review the execution plan on what will be added, changed and detroyed. Acknowledge by typing: yes 

```
%>  terraform apply
```

Your final result should look like:
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
public_ip_address = [ 
  "",
  "",
 ]
```

If you donot see the public_ip_address of the vm. Then run again: "terraform apply".  It will not change anything, but will likely output the IpAddresses.

```
%> terraform apply
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

public_ip_address = [
  "13.69.24.19",
  "40.114.142.194",
]
```

## Now login, if you have your ssh keys properly configured:
```
>$ ssh demouser1@42.71.150.20
...
Last login: Mon Feb  8 09:47:34 2021 from **************************
testuser@demo-link:~$ 

```
 
## Known Bugs
* let me know
