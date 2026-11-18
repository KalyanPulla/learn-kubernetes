resource "azurerm_public_ip" "main" {
  name                = "${var.vm_name}"
  location            = "Denmark East"
  resource_group_name = "denmark-east-rg"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = "Denmark East"
  resource_group_name = "denmark-east-rg"

  ip_configuration {
    name                          = "${var.vm_name}-nic"
    subnet_id                     = "/subscriptions/396632f7-adca-488d-bb48-22d93391890f/resourceGroups/denmark-east-rg/providers/Microsoft.Network/virtualNetworks/vnet-denmarkeast-1/subnets/snet-denmarkeast-1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.vm_name}-vm"
  location              = "Denmark East"
  resource_group_name   = "denmark-east-rg"
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_B1s"

  source_image_id = "/subscriptions/396632f7-adca-488d-bb48-22d93391890f/resourceGroups/denmark-east-rg/providers/Microsoft.Compute/galleries/rhel10/images/1.0.0/versions/1.0.0"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_password = "devops@12345"
  admin_username = "devops"

  disable_password_authentication = false

  secure_boot_enabled = true
  vtpm_enabled        = true

}

provider "azurerm" {
  features {
    
  }
}
variable "vm_name" {
  default = "docker"
}
output "ip" {
  value = azurerm_public_ip.workstation.ip_address
}