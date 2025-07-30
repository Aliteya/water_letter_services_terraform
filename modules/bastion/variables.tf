variable "vpc_id" {
    type = string
}

variable "public_subnet_ids" {
    type = list(string)
    description = "Public Subnet IDs"
}

variable "private_subnet_ids" {
    type = list(string)
    description = "Private Subnet IDs"
}

variable "private_subnet_cidrs" {
    type = list(string)
    description = "Private Subnet CIDR values"
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "ec2_bastion_ingress_ip" {
    type = string
    default = "0.0.0.0/0"
}