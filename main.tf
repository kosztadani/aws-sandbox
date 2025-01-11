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
    default_tags {
        tags = {
            "Terraform-project" = "aws-sandbox"
        }
    }
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

resource aws_default_route_table "my-route-table" {
    default_route_table_id = aws_vpc.my-vpc.default_route_table_id
    tags = {
        Name = "my-route-table"
    }
}

resource aws_route "my-route" {
    route_table_id = aws_default_route_table.my-route-table.id
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
    route_table_id = aws_default_route_table.my-route-table.id
}

resource aws_route_table_association "my-route-table-association-1b" {
    subnet_id = aws_subnet.my-subnet-1b.id
    route_table_id = aws_default_route_table.my-route-table.id
}

resource aws_route_table_association "my-route-table-association-1c" {
    subnet_id = aws_subnet.my-subnet-1c.id
    route_table_id = aws_default_route_table.my-route-table.id
}

resource aws_ec2_instance_connect_endpoint "my-connection-endpoint" {
    subnet_id = aws_subnet.my-subnet-1a.id
    preserve_client_ip = false
    tags = {
        Name = "my-connection-endpoint"
    }
}

resource aws_default_security_group "my-security-group" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
        Name = "my-security-group"
    }
}

resource aws_vpc_security_group_ingress_rule "my-ingress-rule" {
    security_group_id = aws_default_security_group.my-security-group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    description = "my-ingress-rule"
    tags = {
        Name = "my-ingress-rule"
    }
}

resource aws_vpc_security_group_egress_rule "my-egress-rule" {
    security_group_id = aws_default_security_group.my-security-group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    description = "my-egress-rule"
    tags = {
        Name = "my-egress-rule"
    }
}

resource aws_default_network_acl "my-network-acl" {
    default_network_acl_id = aws_vpc.my-vpc.default_network_acl_id
    ingress {
        protocol = -1
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
    egress {
        protocol = -1
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
    subnet_ids = [
        aws_subnet.my-subnet-1a.id,
        aws_subnet.my-subnet-1b.id,
        aws_subnet.my-subnet-1c.id
    ]
    tags = {
        Name = "my-network-acl"
    }
}

resource aws_network_interface "my-network-interfaces" {
    count = local.instances
    subnet_id = aws_subnet.my-subnet-1a.id
    private_ips = [cidrhost("192.168.0.0/24", 10 + count.index)]
    security_groups = [aws_default_security_group.my-security-group.id]
    description = "my-network-interface"
    tags = {
        Name = "my-network-interface-${count.index}"
    }
}

resource aws_vpc_endpoint "my-vpc-endpoint" {
    vpc_id = aws_vpc.my-vpc.id
    service_name = "com.amazonaws.eu-central-1.s3"
    tags = {
        Name = "my-vpc-endpoint"
    }
}

resource aws_vpc_endpoint_route_table_association "my-vpc-endpoint-route-table-association" {
    route_table_id = aws_default_route_table.my-route-table.id
    vpc_endpoint_id = aws_vpc_endpoint.my-vpc-endpoint.id
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

resource local_file "my-ssh-config" {
    filename = "${path.module}/generated/ssh-config"
    content = templatefile("${path.module}/resources/ssh/config.tftpl", {
        proxy_command_script = abspath("${path.module}/scripts/aws-ssh-proxy-command.sh")
        instances = [
            for instance in aws_instance.my-instances : {
                id = instance.id
                name = instance.tags.Name
            }
        ]
    })
    file_permission = "0600"
}
