provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "benchmark" {
  name     = "benchmark_resources"
  location = var.location
}

resource "azurerm_virtual_network" "benchmark_network" {
  name                = "benchmark_network"
  resource_group_name = azurerm_resource_group.benchmark.name
  location            = var.location
  address_space       = [var.network_cidr]
}

resource "azurerm_subnet" "benchmark_public_subnet" {
  name                 = "benchmark_public_subnet"
  resource_group_name  = azurerm_resource_group.benchmark.name
  virtual_network_name = azurerm_virtual_network.benchmark_network.name
  address_prefixes     = [var.public_subnet]
}

resource "azurerm_network_security_group" "benchmark_public_security_group" {
  name                = "benchmark_public_security_group"
  location            = var.location
  resource_group_name = azurerm_resource_group.benchmark.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "benchmark_public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.benchmark_public_subnet.id
  network_security_group_id = azurerm_network_security_group.benchmark_public_security_group.id
}

resource "azurerm_public_ip" "benchmark_bastion_public_ip" {
  name                = "benchmark_bastion_public_ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.benchmark.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "benchmark_bastion_interface" {
  name                = "benchmark_bastion_interface"
  location            = var.location
  resource_group_name = azurerm_resource_group.benchmark.name

  ip_configuration {
    name                          = "benchmark_bastion_ip_cfg"
    subnet_id                     = azurerm_subnet.benchmark_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.benchmark_bastion_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "benchmark_bastion_nic_sg_assoc" {
  network_interface_id      = azurerm_network_interface.benchmark_bastion_interface.id
  network_security_group_id = azurerm_network_security_group.benchmark_public_security_group.id
}

resource "azurerm_subnet" "benchmark_private_subnet" {
  name                 = "benchmark_private_subnet"
  resource_group_name  = azurerm_resource_group.benchmark.name
  virtual_network_name = azurerm_virtual_network.benchmark_network.name
  address_prefixes     = [var.private_subnet]
}

resource "azurerm_network_security_group" "benchmark_private_security_group" {
  name                = "benchmark_private_security_group"
  location            = var.location
  resource_group_name = azurerm_resource_group.benchmark.name

  security_rule {
    name                       = "allow-ssh-from-public-subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.public_subnet
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "benchmark_private_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.benchmark_private_subnet.id
  network_security_group_id = azurerm_network_security_group.benchmark_private_security_group.id
}

resource "azurerm_network_interface" "benchmark_instance_interface" {
  count               = var.instance_count
  name                = "benchmark_instance_interface_${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.benchmark.name

  ip_configuration {
    name                          = "benchmark_instance_ip_cfg_${count.index}"
    subnet_id                     = azurerm_subnet.benchmark_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "benchmark_instance_nic_sg_assoc" {
  count                     = var.instance_count
  network_interface_id      = element(azurerm_network_interface.benchmark_instance_interface.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.benchmark_private_security_group.id
}

resource "azurerm_virtual_machine" "benchmark_bastion_vm" {
  name                  = "benchmark_bastion_vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.benchmark.name
  network_interface_ids = [azurerm_network_interface.benchmark_bastion_interface.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "benchmark_bastion_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "benchbastion"
    admin_username = "az_user"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/az_user/.ssh/authorized_keys"
      key_data = var.ssh_pub_key
    }
  }
}

resource "azurerm_virtual_machine" "benchmark_instance_vm" {
  count                 = var.instance_count
  name                  = "benchmark_instance_${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.benchmark.name
  network_interface_ids = [element(azurerm_network_interface.benchmark_instance_interface.*.id, count.index)]
  vm_size               = "Standard_D4s_v3"

  storage_os_disk {
    name              = "benchmark_instance_disk_${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bench${count.index}"
    admin_username = "az_user"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/az_user/.ssh/authorized_keys"
      key_data = var.ssh_pub_key
    }
  }
}
