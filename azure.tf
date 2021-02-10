#################################################################
#          Terraform file depends on variables.tf               #
#################################################################

#################################################################
#          Terraform file depends on locals.tf                  #
#################################################################

# Some remaining variables are still hardcoded. Such virtual 
# machine details. There are only used once, and most likely they 
# are not required to change


#################################################################
#################### MICROSOFT AZURE SECTION ####################
#################################################################
provider "azurerm" {
    # whilst the `version` attribute is optional,
    # we recommend pinning to a given version of the Provider
    version = "=2.45"
    subscription_id = var.azure_subscription_id
    tenant_id = var.azure_tenant_id
    features {}
}

# Create a resource group
resource "azurerm_resource_group" "atlas-group" {
    name     = local.resource_group_name
    location = local.location

    tags = {
        environment = "Atlas Demo"
    }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "atlas-group" {
    name                = local.vnet_name
    resource_group_name = azurerm_resource_group.atlas-group.name
    location            = azurerm_resource_group.atlas-group.location
    address_space       = local.address_space
 
    tags = {
        environment = "Atlas Demo"
    }
}


# Create a subnet in virtual network,
resource "azurerm_subnet" "atlas-group" {
    name                 = local.subnet
    address_prefixes     = [local.subnet_address_space]
    resource_group_name  = azurerm_resource_group.atlas-group.name
    virtual_network_name = azurerm_virtual_network.atlas-group.name
}

resource "azurerm_public_ip" "demo-vm-ip" {
    name                         = "myPublicIP-${format("%02d", count.index)}"
    count                        = local.azure_vm_count
    location                     = local.location_alt
    resource_group_name          = azurerm_resource_group.atlas-group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Atlas Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "demo-vm-nsg" {
    name                = "myAtlasDemo"
    location            = local.location_alt
    resource_group_name = azurerm_resource_group.atlas-group.name

    # Allow inbound SSH traffic
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment                = "Atlas Demo"
    }
}

# # Create network interface
resource "azurerm_network_interface" "demo-vm-nic" {
    name                      = "myNIC-${format("%02d", count.index)}"
    count                     = local.azure_vm_count
    location                  = azurerm_network_security_group.demo-vm-nsg.location
    resource_group_name       = azurerm_resource_group.atlas-group.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.atlas-group.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.demo-vm-ip.*.id, count.index)
    }

    tags = {
        environment = "Atlas Demo"
    }

    #depends_on = [ azurerm_network_interface.demo-vm-nic ]
}

# # Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "demo-vm" {
#     count                     = length(azurerm_network_interface.demo-vm-nic.*.id)
#     network_interface_id      = element(azurerm_network_interface.demo-vm-nic.*.id, count.index)
#     network_security_group_id = azurerm_network_security_group.demo-vm-nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "demo_nsg_assoc" {
#     subnet_id = azurerm_subnet.atlas-group.id
#     network_security_group_id = azurerm_network_security_group.demo-vm-nsg.id
# }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "demo-vm" {
    name                  = "${local.azure_vm_name}-${format("%02d", count.index)}"
    count                 = local.azure_vm_count
    location              = local.location_alt
    resource_group_name   = azurerm_resource_group.atlas-group.name
    size                  = local.azure_vm_size
    admin_username        = local.admin_username
    admin_password        = var.admin_password
    network_interface_ids = [
	    element(azurerm_network_interface.demo-vm-nic.*.id, count.index)
    ]

    admin_ssh_key {
        username   = local.admin_username
        public_key = file(var.public_key_path)
    }

    os_disk {     
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher         = "Canonical"
        offer             = "UbuntuServer"
        sku               = "18.04-LTS"
        version           = "latest"
    }

    tags = {
        environment       = "Demo"
    }

    connection {
        disable_password_authentication = true
        type 				= "ssh"
        host 				= self.public_ip_address
        user 				= self.admin_username
        password 			= self.admin_password
        agent 				= true
        private_key 			= file(var.private_key_path)
    }

    provisioner "remote-exec" {

        connection {
            host = self.public_ip_address
            user = self.admin_username
            password = self.admin_password
        }

        inline = [
        "sleep 10",
        "sudo rm -f /etc/resolv.conf ; sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf",
        "sudo apt-get -y update",
        "sudo apt-get -y install python3-pip",
        "sudo apt-get -y update",
        "sudo pip3 install pymongo==3.9.0",
        "sudo pip3 install faker",
        "sudo pip3 install dnspython",

        "wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -",
        "echo 'deb [ arch=amd64 ] http://repo.mongodb.com/apt/ubuntu bionic/mongodb-enterprise/4.4 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-enterprise.list",
        "sudo apt-get update",
	    "sudo apt-get install -y mongodb-enterprise-shell"
        ]
    }
}

output "public_ip_address" {
  description = "Public IP of azure VM"
  value       = azurerm_public_ip.demo-vm-ip.*.ip_address
}
