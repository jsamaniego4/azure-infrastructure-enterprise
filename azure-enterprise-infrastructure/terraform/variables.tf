variable "subscription_id" {
  type = string
}
variable "location" {
  type    = string
  default = "eastus"
}
variable "prefix" {
  type    = string
  default = "js-cloudlab"
}
variable "admin_source_cidr" {
  type        = string
  description = "Your public IP in /32 CIDR notation. Do not expose SSH to the internet."
  validation {
    condition     = can(cidrhost(var.admin_source_cidr, 0)) && var.admin_source_cidr != "0.0.0.0/0"
    error_message = "Enter a valid restricted CIDR, not 0.0.0.0/0."
  }
}
variable "ssh_public_key" {
  type        = string
  description = "SSH public key, not private key"
}
variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}
