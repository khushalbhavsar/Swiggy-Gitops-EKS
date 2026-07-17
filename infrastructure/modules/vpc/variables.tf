variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "Jumphost-vpc"
}

variable "igw_name" {
  description = "Internet Gateway name"
  type        = string
  default     = "Jumphost-igw"
}

variable "public_subnet_name1" {
  description = "Public Subnet 1 Name"
  type        = string
  default     = "Public-Subnet-1"
}

variable "public_subnet_name2" {
  description = "Public Subnet 2 Name"
  type        = string
  default     = "Public-subnet2"
}

variable "private_subnet_name1" {
  description = "Private Subnet 1 Name"
  type        = string
  default     = "Private-subnet1"
}

variable "private_subnet_name2" {
  description = "Private Subnet 2 Name"
  type        = string
  default     = "Private-subnet2"
}

variable "rt_name" {
  description = "Route Table Name"
  type        = string
  default     = "Jumphost-rt"
}

variable "sg_name" {
  description = "Security Group Name"
  type        = string
  default     = "Jumphost-sg"
}
