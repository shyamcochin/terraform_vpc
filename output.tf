output "vpc_arn" {
  value = aws_vpc.custom_vpc.arn
}

output "vpc_id" {
  value = aws_vpc.custom_vpc.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = concat(aws_vpc.custom_vpc.*.cidr_block, [""])[0]
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet.*.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnet.*.id
}

output "nat_id" {
  value = "${aws_nat_gateway.nat_gateway.*.id}"
}

output "nat_eip" {
  value = "${aws_eip.nat-gateway-eip.*.public_ip}"
}