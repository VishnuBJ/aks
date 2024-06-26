# Create a resource group
resource "azurerm_resource_group" "robot" {
  name     = "test"
  location = "centralindia"
}

# Virtual Network
resource "azurerm_virtual_network" "robot" {
  name                = "robotVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.robot.location
  resource_group_name = azurerm_resource_group.robot.name
}

# Subnet
resource "azurerm_subnet" "robot" {
  name                 = "robotSubnet"
  resource_group_name  = azurerm_resource_group.robot.name
  virtual_network_name = azurerm_virtual_network.robot.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.robot.location
  resource_group_name = azurerm_resource_group.robot.name

  security_rule {
    name                       = "AllowAnyCustom8080Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Subnet Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.robot.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "robotAKSCluster"
  location            = azurerm_resource_group.robot.location
  resource_group_name = azurerm_resource_group.robot.name
  dns_prefix          = "robotaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"

    vnet_subnet_id = azurerm_subnet.robot.id
    
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3

  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"

  }

  tags = {
    Environment = "Assessment"
  }
}

