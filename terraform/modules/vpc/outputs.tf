output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets_id" {
  value = [for subnet in values(aws_subnet.Public) : subnet.id]
}

output "private_subnets_id" {
  value = [for subnet in values(aws_subnet.Private) : subnet.id]
}