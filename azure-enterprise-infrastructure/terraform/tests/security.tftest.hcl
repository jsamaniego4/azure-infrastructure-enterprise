mock_provider "azurerm" {}
variables {
  subscription_id   = "00000000-0000-0000-0000-000000000001"
  admin_source_cidr = "198.51.100.10/32"
  ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f test"
  alert_email       = "lab@example.com"
}
run "security_defaults" {
  command = plan
  assert {
    condition     = azurerm_linux_virtual_machine.lab.disable_password_authentication
    error_message = "Password authentication must be disabled."
  }
  assert {
    condition     = azurerm_linux_virtual_machine.lab.identity[0].type == "SystemAssigned"
    error_message = "VM must use a managed identity."
  }
  assert {
    condition     = length(azurerm_network_security_group.app.security_rule) == 1 && alltrue([for rule in azurerm_network_security_group.app.security_rule : rule.destination_port_range == "22" && rule.source_address_prefix == "198.51.100.10/32" && rule.access == "Allow"])
    error_message = "Only allowlisted SSH may be explicitly allowed."
  }
  assert {
    condition     = azurerm_role_assignment.vm_reader.role_definition_name == "Reader"
    error_message = "VM must receive only Reader access."
  }
  assert {
    condition     = length(azurerm_monitor_metric_alert.high_cpu.action) == 1
    error_message = "CPU alert must have a notification action."
  }
}
run "reject_global_ssh" {
  command = plan
  variables { admin_source_cidr = "0.0.0.0/0" }
  expect_failures = [var.admin_source_cidr]
}
run "reject_broad_ssh" {
  command = plan
  variables { admin_source_cidr = "198.51.100.0/24" }
  expect_failures = [var.admin_source_cidr]
}
run "reject_ipv6_ssh" {
  command = plan
  variables { admin_source_cidr = "::/32" }
  expect_failures = [var.admin_source_cidr]
}
