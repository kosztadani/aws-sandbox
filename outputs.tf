output "my-ip-address" {
    description = "my-ip-address"
    value = aws_eip.my-public-ips[*].public_ip
}
