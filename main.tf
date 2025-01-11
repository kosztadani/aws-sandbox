terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
        local = {
            source = "hashicorp/local"
            version = "~> 2.0"
        }
    }
}

provider aws {
}

terraform {
    backend "s3" {
    }
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

resource aws_subnet "my-subnet-1a" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "eu-central-1a"
    depends_on = [aws_internet_gateway.my-gateway]
    tags = {
        Name = "my-subnet-1a"
    }
}

resource aws_subnet "my-subnet-1b" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "eu-central-1b"
    depends_on = [aws_internet_gateway.my-gateway]
    tags = {
        Name = "my-subnet-1b"
    }
}

resource aws_subnet "my-subnet-1c" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "eu-central-1c"
    depends_on = [aws_internet_gateway.my-gateway]
    tags = {
        Name = "my-subnet-1c"
    }
}

resource aws_route_table_association "my-route-table-association-1a" {
    subnet_id = aws_subnet.my-subnet-1a.id
    route_table_id = aws_route_table.my-route-table.id
}

resource aws_route_table_association "my-route-table-association-1b" {
    subnet_id = aws_subnet.my-subnet-1b.id
    route_table_id = aws_route_table.my-route-table.id
}

resource aws_route_table_association "my-route-table-association-1c" {
    subnet_id = aws_subnet.my-subnet-1c.id
    route_table_id = aws_route_table.my-route-table.id
}

resource aws_ec2_instance_connect_endpoint "my-connection-endpoint" {
    subnet_id = aws_subnet.my-subnet-1a.id
    tags = {
        Name = "my-connection-endpoint"
    }
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
    description = "my-ingress-rule"
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

resource aws_network_interface "my-network-interfaces" {
    count = local.instances
    subnet_id = aws_subnet.my-subnet-1a.id
    private_ips = [cidrhost("192.168.0.0/24", 10 + count.index)]
    security_groups = [aws_security_group.my-security-group.id]
    description = "my-network-interface"
    tags = {
        Name = "my-network-interface-${count.index}"
    }
}

data local_file my-public-key {
    filename = "${path.module}/resources/ssh/my-key"
}

resource aws_key_pair "my-key" {
    public_key = data.local_file.my-public-key.content
    key_name = "my-key"
    tags = {
        Name = "my-key"
    }
}

resource aws_eip "my-public-ips" {
    count = local.instances
    domain = "vpc"
    network_interface = aws_network_interface.my-network-interfaces[count.index].id
    associate_with_private_ip = cidrhost("192.168.0.0/24", 10 + count.index)
    tags = {
        Name = "my-public-ip-${count.index}"
    }
}

data aws_iam_policy_document "my-assume-role-policy-document" {
    statement {
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
        actions = [
            "sts:AssumeRole"
        ]
    }
}

resource aws_iam_role "my-role" {
    name = "my-role"
    assume_role_policy = data.aws_iam_policy_document.my-assume-role-policy-document.json
    tags = {
        Name = "my-role"
    }
}

data aws_iam_policy_document "my-s3-policy-document" {
    statement {
        effect = "Allow"
        actions = [
            "s3:ListBucket"
        ]
        resources = [
            "arn:aws:s3:::sandbox.aws.kosztadani.me"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "s3:GetObject"
        ]
        resources = [
            "arn:aws:s3:::sandbox.aws.kosztadani.me/*"
        ]
    }
}

resource aws_iam_policy "my-s3-policy" {
    name = "my-policy"
    policy = data.aws_iam_policy_document.my-s3-policy-document.json
    tags = {
        Name = "my-s3-policy"
    }
}

resource aws_iam_role_policy_attachment "my-s3-policy-attachment" {
    role = aws_iam_role.my-role.name
    policy_arn = aws_iam_policy.my-s3-policy.arn
}

resource aws_iam_instance_profile "my-instance-profile" {
    name = "my-instance-profile"
    role = aws_iam_role.my-role.name
    tags = {
        Name = "my-instance-profile"
    }
}

resource aws_instance "my-instances" {
    count = local.instances
    ami = "ami-042e6fdb154c830c5" // Debian 12 (HVM)
    instance_type = "t2.nano"
    key_name = aws_key_pair.my-key.key_name
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.my-network-interfaces[count.index].id
    }
    associate_public_ip_address = aws_eip.my-public-ips[count.index].address
    user_data = file("${path.module}/resources/setup.sh")
    iam_instance_profile = aws_iam_instance_profile.my-instance-profile.name
    tags = {
        Name = "my-instance-${count.index}"
    }
}