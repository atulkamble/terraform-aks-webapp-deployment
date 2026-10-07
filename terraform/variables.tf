variable "subscription_id" {
  description = "Azure subscription used to provision the platform."
  type        = string
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "resource_group_name" {
  type    = string
  default = "rg-aks-production"
}

variable "aks_name" {
  type    = string
  default = "aks-production"
}

variable "acr_name" {
  description = "Globally unique ACR name: 5–50 alphanumeric characters."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR names must contain 5–50 alphanumeric characters."
  }
}

variable "vnet_name" {
  type    = string
  default = "vnet-aks-production"
}

variable "admin_principal_ids" {
  description = "Entra object IDs of operators and the application pipeline identity granted AKS access."
  type        = set(string)
  validation {
    condition = length(var.admin_principal_ids) > 0 && alltrue([
      for id in var.admin_principal_ids : can(regex("^[0-9a-fA-F-]{36}$", id))
    ])
    error_message = "Provide at least one Entra object ID for cluster administration."
  }
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "AKS-WebApp"
  }
}
