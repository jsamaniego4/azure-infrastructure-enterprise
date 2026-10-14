output "resource_group" {
  value = azurerm_resource_group.lab.name
}
output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}
output "vnet_id" {
  value = azurerm_virtual_network.lab.id
}
