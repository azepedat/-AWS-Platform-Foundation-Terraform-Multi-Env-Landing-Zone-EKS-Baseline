variable "vpc_name" {
    description = "Name of the VPC"
    type = string
}

variable "vpc_cidr" { 
    description = "CIDR block for the VPC"
    type = string
}

variable "public_subnets" {
    description = "List of CIDR blocks for public subnets"
    type = list(string)
}

variable "private_subnets" {
    description = "List of CIDR blocks for private subnets"
    type = list(string)
}

variable "azs" {
    description = "List of availability zones for the subnets"
    type = list(string)
}

variable "enable_nat_gateway" {
    description = "Enable NAT Gateway for private subnets"
    type = bool
    default = true
}

variable "single_nat_gateway" { 
    description = "Use a single NAT Gateway for all private subnets"
    type = bool
    default = false
}

variable "tags" { 
    description = "Tags to apply to all resources"
    type = map(string)
    default = {}
}

# What this does: Defines all the inputs the module needs (VPC size, subnets, etc.).