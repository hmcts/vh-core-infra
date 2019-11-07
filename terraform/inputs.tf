variable "location" {
    type = "string"
    default = "ukwest"
}

variable "build_agent_vnet" {
    type = "string"
    default = "/subscriptions/705b2731-0e0b-4df7-8630-95f157f0a347/resourceGroups/vh-devtestlabs-dev/providers/Microsoft.Network/virtualNetworks/Dtlvh-devtestlabs-dev/subnets/Dtlvh-devtestlabs-devSubnet"
}

variable "idam_tenant_id" {
    type = "string"
    default = ""
}

variable "idam_client_id" {
    type = "string"
    default = ""
}

variable "idam_client_secret" {
    type = "string"
    default = ""
}

variable "dns_tenant_id" {
    type = "string"
    default = ""
}

variable "dns_client_id" {
    type = "string"
    default = ""
}

variable "dns_client_secret" {
    type = "string"
    default = ""
}

variable "dns_subscription_id" {
    type = "string"
    default = ""
}
