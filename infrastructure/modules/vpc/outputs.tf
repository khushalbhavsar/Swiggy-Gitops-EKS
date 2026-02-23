output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet1_id" {
  description = "ID of public subnet 1"
  value       = aws_subnet.public-subnet1.id
}

output "public_subnet2_id" {
  description = "ID of public subnet 2"
  value       = aws_subnet.public-subnet2.id
}

output "private_subnet1_id" {
  description = "ID of private subnet 1"
  value       = aws_subnet.private-subnet1.id
}

output "private_subnet2_id" {
  description = "ID of private subnet 2"
  value       = aws_subnet.private-subnet2.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.security-group.id
}
