resource "azurerm_resource_group" "lab" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}
resource "azurerm_virtual_network" "lab" {
  tags                = var.tags
  name                = "${var.prefix}-vnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}
resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.20.1.0/24"]
}
resource "azurerm_network_security_group" "app" {
  tags                = var.tags
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  security_rule {
    name                       = "ssh-from-admin-only"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
resource "azurerm_public_ip" "vm" {
  tags                = var.tags
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_network_interface" "vm" {
  tags                = var.tags
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}
resource "azurerm_linux_virtual_machine" "lab" {
  tags                            = var.tags
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]
  depends_on                      = [azurerm_subnet_network_security_group_association.app]
  identity { type = "SystemAssigned" }
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
resource "azurerm_monitor_metric_alert" "high_cpu" {
  tags                = var.tags
  name                = "${var.prefix}-high-cpu"
  resource_group_name = azurerm_resource_group.lab.name
  scopes              = [azurerm_linux_virtual_machine.lab.id]
  description         = "Alert when average CPU is greater than 80 percent for 5 minutes"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"
  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}

resource "azurerm_monitor_action_group" "ops" {
  name                = "${var.prefix}-ops"
  resource_group_name = azurerm_resource_group.lab.name
  short_name          = "lab-ops"
  tags                = var.tags
  email_receiver {
    name                    = "lab-owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Demonstrates least privilege: the VM can inspect only its own resource group.
resource "azurerm_role_assignment" "vm_reader" {
  scope                = azurerm_resource_group.lab.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.lab.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
