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
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.prefix))
    error_message = "Use 3–20 lowercase letters, digits or hyphens, starting with a letter."
  }
}
variable "admin_source_cidr" {
  type        = string
  description = "Your public IP in /32 CIDR notation. Do not expose SSH to the internet."
  validation {
    condition     = can(cidrnetmask(var.admin_source_cidr)) && can(regex("/32$", var.admin_source_cidr)) && !startswith(var.admin_source_cidr, "0.")
    error_message = "Enter a valid IPv4 host CIDR ending in /32 (not 0.0.0.0)."
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

variable "alert_email" {
  type        = string
  description = "Email destination for CPU alerts."
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "Enter a valid alert email address."
  }
}
variable "tags" {
  type = map(string)
  default = {
    project     = "azure-enterprise-infrastructure"
    environment = "lab"
    managed_by  = "terraform"
  }
}
