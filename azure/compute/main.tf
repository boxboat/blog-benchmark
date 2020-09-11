provider "azurerm" {
  features {}
}

resource "azurerm_network_interface" "nic" {
  name                = "instance_nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "instance_ip_cfg"
    private_ip_address_allocation = "Dynamic"
    subnet_id = var.subnet_id
  }
}

resource "azurerm_virtual_machine" "instance" {
  name                  = "instance"
  location              = var.location
  resource_group_name   = var.resource_group
  vm_size               = "Standard_B1s"

  network_interface_ids = [azurerm_network_interface.nic.id]

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "instance_disk"
    create_option = "FromImage"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name = "instance"
    admin_username = "azadmin"
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
