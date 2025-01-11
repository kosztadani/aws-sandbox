output "my-instances" {
    description = "my-instances"
    value = [
        for instance in aws_instance.my-instances : {
            id = instance.id
            ip = instance.public_ip
            name = instance.tags.Name
        }
    ]
}
