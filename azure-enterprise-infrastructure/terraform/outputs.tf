output "resource_group" {
  value = azurerm_resource_group.lab.name
}
output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}
output "vnet_id" {
  value = azurerm_virtual_network.lab.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.lab.name
}
output "vm_principal_id" {
  value = azurerm_linux_virtual_machine.lab.identity[0].principal_id
}
output "cpu_alert_name" {
  value = azurerm_monitor_metric_alert.high_cpu.name
}
