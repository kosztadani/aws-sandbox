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

resource aws_internet_gateway "my-internet-gateway" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
        Name = "my-internet-gateway"
    }
}

resource aws_default_route_table "my-default-route-table" {
    default_route_table_id = aws_vpc.my-vpc.default_route_table_id
    tags = {
        Name = "my-default-route-table"
    }
}

resource aws_route "my-default-route" {
    route_table_id = aws_default_route_table.my-default-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = local.nat_gateways == 1 ? aws_nat_gateway.my-nat-gateway[0].id : null
    gateway_id = local.nat_gateways == 0 ? aws_internet_gateway.my-internet-gateway.id : null
}

resource aws_subnet "my-private-subnet" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "eu-central-1a"
    tags = {
        Name = "my-private-subnet"
    }
}

resource aws_subnet "my-public-subnet" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "eu-central-1a"
    tags = {
        Name = "my-public-subnet"
    }
}

resource aws_route_table "my-public-route-table" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
        Name = "my-public-route-table"
    }
}

resource aws_route "my-public-route" {
    route_table_id = aws_route_table.my-public-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gateway.id
}

resource aws_eip "my-nat-public-ip" {
    count = local.nat_gateways
    domain = "vpc"
    associate_with_private_ip = cidrhost("192.168.0.0/24", 5 + count.index)
    tags = {
        Name = "my-nat-public-ip"
    }
}

resource aws_nat_gateway "my-nat-gateway" {
    count = local.nat_gateways
    subnet_id = aws_subnet.my-public-subnet.id
    allocation_id = aws_eip.my-nat-public-ip[count.index].id
    tags = {
        Name = "my-nat-gateway"
    }
}

resource aws_route_table_association "my-default-route-table-association" {
    subnet_id = aws_subnet.my-private-subnet.id
    route_table_id = aws_default_route_table.my-default-route-table.id
}

resource aws_route_table_association "my-public-route-table-association" {
    subnet_id = aws_subnet.my-public-subnet.id
    route_table_id = aws_route_table.my-public-route-table.id
}

resource aws_ec2_instance_connect_endpoint "my-connection-endpoint" {
    subnet_id = aws_subnet.my-public-subnet.id
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
        aws_subnet.my-private-subnet.id,
        aws_subnet.my-public-subnet.id,
    ]
    tags = {
        Name = "my-network-acl"
    }
}

resource aws_network_interface "my-network-interfaces" {
    count = local.instances
    subnet_id = aws_subnet.my-private-subnet.id
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
    route_table_id = aws_default_route_table.my-default-route-table.id
    vpc_endpoint_id = aws_vpc_endpoint.my-vpc-endpoint.id
}

resource aws_eip "my-public-ips" {
    count = local.public_ips
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
            "arn:aws:s3:::${var.s3_bucket}"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "s3:GetObject"
        ]
        resources = [
            "arn:aws:s3:::${var.s3_bucket}/*"
        ]
    }
    # The following bucket is public, but uses "requester pays", so access
    # must be granted explicitly if not using the same AWS account.
    statement {
        effect = "Allow"
        actions = [
            "s3:ListBucket"
        ]
        resources = [
            "arn:aws:s3:::requester-pays.public.s3.aws.kosztadani.me"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "s3:GetObject"
        ]
        resources = [
            "arn:aws:s3:::requester-pays.public.s3.aws.kosztadani.me/*"
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
    associate_public_ip_address = local.public_ips == 0 ? null : aws_eip.my-public-ips[count.index].address
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
