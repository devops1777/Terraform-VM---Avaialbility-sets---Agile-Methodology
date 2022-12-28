# Declare the required Azure resource manager provider and specify its version.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.36.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create an Azure resource group.

resource "azurerm_resource_group" "Tarun-VM1" {
  name     = "Tarun-VM1"
  location = "UK South"
}

# Create an Azure virtual network within the resource group.

resource "azurerm_virtual_network" "Tarun-VN1" {
  name                = "Tarun-VN1"
  location            = azurerm_resource_group.Tarun-VM1.location
  resource_group_name = azurerm_resource_group.Tarun-VM1.name
  address_space       = ["10.0.0.0/16"]

  depends_on = [
    azurerm_resource_group.Tarun-VM1
  ]
}

# Creat an Availability set

resource "azurerm_availability_set" "Tarun-AS1" {
  name                         = "Tarun-AS1"
  location                     = azurerm_resource_group.Tarun-VM1.location
  resource_group_name          = azurerm_resource_group.Tarun-VM1.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2

}
# Create an Azure subnet within the virtual network.

resource "azurerm_subnet" "Tarun-SN1" {
  name                 = "Tarun-SN1"
  resource_group_name  = azurerm_resource_group.Tarun-VM1.name
  virtual_network_name = azurerm_virtual_network.Tarun-VN1.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [
    azurerm_virtual_network.Tarun-VN1
  ]
}

# Create an Azure network interface within the subnet.

resource "azurerm_network_interface" "Tarun-NI1" {
  name                = "Tarun-NI1"
  location            = azurerm_resource_group.Tarun-VM1.location
  resource_group_name = azurerm_resource_group.Tarun-VM1.name

  ip_configuration {
    name                          = "Tarun-IP1"
    subnet_id                     = azurerm_subnet.Tarun-SN1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Tarun-PIP1.id
  }

  depends_on = [
    azurerm_subnet.Tarun-SN1,
    azurerm_public_ip.Tarun-PIP1
  ]
}

# Create an Azure Windows virtual machine using the network interface and the specified image.

resource "azurerm_windows_virtual_machine" "Tarun-WVM1" {
  name                = "Tarun-WVM1"
  location            = azurerm_resource_group.Tarun-VM1.location
  resource_group_name = azurerm_resource_group.Tarun-VM1.name
  size                = "Standard_B1s"
  admin_username      = "tarunVM1"
  admin_password      = "P@ssword1777"
  availability_set_id = azurerm_availability_set.Tarun-AS1.id

  network_interface_ids = [
    azurerm_network_interface.Tarun-NI1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.Tarun-NI1,
    azurerm_availability_set.Tarun-AS1
  ]
}

# Create a public IP address and apply tags.

resource "azurerm_public_ip" "Tarun-PIP1" {
  name                = "Tarun-PIP1"
  resource_group_name = azurerm_resource_group.Tarun-VM1.name
  location            = azurerm_resource_group.Tarun-VM1.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

# Create a managed disk.

resource "azurerm_managed_disk" "Tarun-VM-SG1" {
  name                 = "Tarun-VM-SG1"
  resource_group_name  = azurerm_resource_group.Tarun-VM1.name
  location             = azurerm_resource_group.Tarun-VM1.location
  create_option        = "Empty"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 8
}


# Attach the managed disk to the virtual machine as a data disk.

resource "azurerm_virtual_machine_data_disk_attachment" "Tarun-DA1" {
  managed_disk_id    = azurerm_managed_disk.Tarun-VM-SG1.id
  virtual_machine_id = azurerm_windows_virtual_machine.Tarun-WVM1.id
  lun                = "0"
  caching            = "ReadWrite"

  depends_on = [
    azurerm_windows_virtual_machine.Tarun-WVM1,
    azurerm_managed_disk.Tarun-VM-SG1
  ]
}