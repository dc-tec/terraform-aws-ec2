terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.7.0"
}

data "aws_region" "current" {}

data "aws_security_group" "main" {
  for_each = var.ec2_instance_config

  dynamic "filter" {
    for_each = each.value.security_group_name

    content {
      name   = "tag:Name"
      values = ["sg-${filter.value}-${data.aws_region.current.name}"]
    }
  }
}

data "aws_subnet" "main" {
  for_each = var.ec2_instance_config

  filter {
    name   = "tag:Name"
    values = ["sn-${each.value.subnet_name}-${each.value.availability_zone}"]
  }
}

resource "tls_private_key" "main" {
  for_each = var.ec2_instance_config

  algorithm = "RSA"
}

resource "aws_key_pair" "main" {
  for_each = var.ec2_instance_config

  key_name   = "${each.key}-ssh_key"
  public_key = tls_private_key.main[each.key].public_key_openssh
}

resource "local_file" "main" {
  for_each = var.ec2_instance_config

  content  = tls_private_key.main[each.key].private_key_pem
  filename = "${each.key}-ssh_key.pem"
}

resource "aws_instance" "main" {
  for_each = var.ec2_instance_config

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  key_name                    = aws_key_pair.main[each.key].key_name
  vpc_security_group_ids      = [data.aws_security_group.main[each.key].id]
  subnet_id                   = data.aws_subnet.main[each.key].id
  associate_public_ip_address = each.value.associate_public_ip_address
  availability_zone           = each.value.availability_zone

  tags = merge(
    var.tags,
    {
      "Name" = "ec2-${each.key}-${data.aws_region.current.name}"
    }
  )
}