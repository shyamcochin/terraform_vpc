### Provider Configuration Sections:
#===================================
variable "region" {
    type = string
    description = "To provide the default region"
}

### Tags Configuration Sections:
#==============================
variable "project_tags" {
  type        = map(string)
  description = "It will take from Project Tags"
}

variable "environment_tags" {
  type        = map(string)
  description = "It will take from Environment Tags"
}

### VPC Configuration Sections:
#==============================
variable "vpc_cidr_block" {
  type        = string
  #default     = "10.10.0.0/16"
  description = "CIDR block range for vpc"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Instance Tenancy for vpc"
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Instance Tenancy for vpc"
}

variable "vpc_instance_tenancy" {
  type        = string
  default     = "default"
  description = "Instance Tenancy for vpc"
}


### Subnet Configuration Sections:
#=================================
variable "number_of_private_subnets" {
  type        = number
  #default     = 2
  description = "The number of private subnets in a VPC."
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  #default     = ["10.10.1.0/24", "10.10.2.0/24"]
  description = "CIDR block range for the private subnets"
}

variable "number_of_public_subnets" {
  type        = number
  #default     = 2
  description = "The number of Public subnets in a VPC."
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  #default     = ["10.10.3.0/24", "10.10.4.0/24"]
  description = "CIDR block range for the public subnets"
}


### EIP and NAT Configuration Sections:
#======================================
variable "enable_nat_gateway" {
  type        = bool
# default     = 0
  description = "The number of EIP in a VPC."
}
