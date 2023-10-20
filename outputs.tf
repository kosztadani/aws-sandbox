output "my-ip-address" {
    description = "my-ip-address"
    value = aws_eip.my-public-ip.public_ip
}
