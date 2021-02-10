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

