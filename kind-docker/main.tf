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
  size                  = "Standard_D2s_v5"

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
  value = azurerm_public_ip.main.ip_address
}

resource "null_resource" "kind-setup" {
  depends_on = [ azurerm_linux_virtual_machine.main ]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = azurerm_public_ip.main.ip_address
      user = "devops"
      password = "devops@12345"
    }
    inline = [
        "sudo dnf -y install dnf-plugins-core",
        "sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo",
        "sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y",
        "sudo systemctl enable docker",
        "sudo systemctl start docker",
        "sudo usermod -a -G docker devops",
        "sudo curl -Lo /bin/kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64",
        "sudo curl -Lo /bin/kubectl https://dl.k8s.io/release/v1.36.1/bin/linux/amd64/kubectl",
        "sudo chmod ugo+x /bin/kind /bin/kubectl",
        "sudo kind create cluster --name rhel10-cluster"
      ]
  }
}