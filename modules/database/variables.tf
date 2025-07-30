variable "vpc_id" {
    type = string
}

variable "public_subnet_ids" {
    type = list(string)
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "ecs_tasks_sg_id" {
    type = string
}

variable "private_subnet_cidrs" {
    type = list(string)
    description = "Private Subnet CIDR values"
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "nat_instance_sg_id" {
    type = string
}

variable "database_credentials" {
    type = map(string)
}