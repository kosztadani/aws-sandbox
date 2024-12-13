output "my-ip-address" {
    description = "my-ip-address"
    value = aws_eip.my-public-ips[*].public_ip
}

output "my-instance-id" {
    description = "my-instance-id"
    value = aws_instance.my-servers[*].id
}
