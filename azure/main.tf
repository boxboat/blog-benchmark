provider "azurerm" {
  features {}
}

resource "azurerm_public_ip" "benchmark_public_ip" {
  name                = "benchmark_public_ip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "instance_nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "instance_ip_cfg"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = azurerm_public_ip.benchmark_public_ip.id
  }
}

resource "azurerm_virtual_machine" "instance" {
  name                = "instance"
  location            = var.location
  resource_group_name = var.resource_group
  vm_size             = "Standard_B1s"

  network_interface_ids = [azurerm_network_interface.nic.id]

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name          = "instance_disk"
    create_option = "FromImage"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "instance"
    admin_username = "azadmin"
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/azadmin/.ssh/authorized_keys"
      key_data = var.ssh_pub_key
    }
  }
}

data "azurerm_public_ip" "benchmark_public_ip" {
  name                = azurerm_public_ip.benchmark_public_ip.name
  resource_group_name = azurerm_virtual_machine.instance.resource_group_name
  depends_on          = [azurerm_public_ip.benchmark_public_ip, azurerm_virtual_machine.instance]
}
