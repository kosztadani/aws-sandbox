terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider aws {
}

resource aws_vpc "my-vpc" {
    cidr_block = "192.168.0.0/16"
    tags = {
        Name = "my-vpc"
    }
}

resource aws_internet_gateway "my-gateway" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
        Name = "my-gateway"
    }
}

resource aws_route_table "my-route-table" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
        Name = "my-route-table"
    }
}

resource aws_route "my-route" {
    route_table_id = aws_route_table.my-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-gateway.id
}

resource aws_subnet "my-subnet" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "eu-central-1a"
    depends_on = [aws_internet_gateway.my-gateway]
    tags = {
        Name = "my-subnet"
    }
}

resource aws_route_table_association "my-route-table-association" {
    subnet_id = aws_subnet.my-subnet.id
    route_table_id = aws_route_table.my-route-table.id
}

resource aws_security_group "my-security-group" {
    name = "my-security-group"
    vpc_id = aws_vpc.my-vpc.id
    description = "my-security-group"
    tags = {
        Name = "my-security-group"
    }
}

resource aws_vpc_security_group_ingress_rule "my-ingress-rule" {
    security_group_id = aws_security_group.my-security-group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    description = "my-inress-rule"
    tags = {
        Name = "my-ingress-rule"
    }
}

resource aws_vpc_security_group_egress_rule "my-egress-rule" {
    security_group_id = aws_security_group.my-security-group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    description = "my-egress-rule"
    tags = {
        Name = "my-egress-rule"
    }
}

resource aws_network_interface "my-network-interface" {
    subnet_id = aws_subnet.my-subnet.id
    private_ips = ["192.168.0.4"]
    security_groups = [aws_security_group.my-security-group.id]
    description = "my-network-interface"
    tags = {
        Name = "my-network-interface"
    }
}

resource aws_key_pair "my-key" {
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcilddbNNCI60MPU50yy2ctMAOzXWmiC9tuhc4xdzx8JPwXcTx83QgY/qm3y0g2ulLkyMh9LUzETm7ci7SWGBB63s9/68aTDv5zpyufT+nv8ABmUhYtOfS2Ngfa1ruwvHpLgB1Y8aUtqz3likLMGDYgDwWFEr1aboGv4tNCJSqsJ9gxIiRv5VTgXBkmST6wI9Z7jE0mDpTvEKKuc4sM2umUOe+Aa++NjyquhMNlURwkbnN0KyE2wLN5PQbZBImXKAtqT8lkLRM6JHLpgBxaIgmgSMWVna1tMJVM93jVL6LF0CHdl3KNIxXGvRzBSST/nli+v8EYOifGuOBJMGi4xPD"
    key_name = "my-key"
    tags = {
        Name = "my-key"
    }
}

resource aws_eip "my-public-ip" {
    domain = "vpc"
    network_interface = aws_network_interface.my-network-interface.id
    associate_with_private_ip = "192.168.0.4"
    tags = {
        Name = "my-public-ip"
    }
}

resource aws_instance "my-server" {
    ami = "ami-05ee09b16a3aaa2fd" // Debian 12 (HVM)
    instance_type = "t2.nano"
    key_name = aws_key_pair.my-key.key_name
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.my-network-interface.id
    }
    associate_public_ip_address = aws_eip.my-public-ip.address
    tags = {
        Name = "my-server"
    }
}
