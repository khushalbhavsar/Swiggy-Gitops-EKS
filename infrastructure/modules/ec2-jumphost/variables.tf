
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam-role" {
  description = "IAM Role for the Jumphost Server"
  type        = string
  default     = "Jumphost-iam-role1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0f3caa1cf4417e51b" // Replace with the latest AMI ID for your region
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "EC2 keypair"
  type        = string
  default     = "awsKey"   // Replace with the keypair
}

variable "instance_name" {
  description = "EC2 Instance name for the jumphost server"
  type        = string
  default     = "Jumphost-server"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID for the EC2 instance"
  type        = string
}
