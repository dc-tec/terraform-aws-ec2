# Terraform AWS EC2 Instance Module
This module manages the creation of EC2 instances in AWS, along with associated resources like security groups, key pairs, and local files for storing private keys.

## Requirements

- Terraform version 1.7.0 or newer
- AWS provider version 5.0 or newer
- TLS provider version 3.0 or newer
- Local provider version 2.0 or newer

## Providers

- AWS
- TLS
- Local

## Resources
- `aws_region.current`: This data source provides the current region.
- `aws_security_group.main`: This data source fetches the security group associated with each EC2 instance.
- `aws_subnet.main`: This data source fetches the subnet associated with each EC2 instance.
- `tls_private_key.main`: This resource creates a private key for each EC2 instance.
- `aws_key_pair.main`: This resource creates a key pair for each EC2 instance using the generated private key.
- `local_file.main`: This resource creates a local file containing the private key for each EC2 instance.
- `aws_instance.main`: This resource creates the EC2 instances.

## Inputs
- `ec2_instance_config`: A map where each item represents an EC2 instance configuration.

## Outputs
- `instance_ids`: The IDs of the created EC2 instances.
- `key_pair_names`: The names of the created key pairs.
- `private_key_files`: The paths to the local files containing the private keys.

## Example Usage
The module can be used in the following way. Please note that a private/public keypair is created on the local machine. In a later version we will update this so it write to a KMS.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.7.0"
}

provider "aws" {
  region = var.region
}

locals {
  ec2_instance_config = {
    for ec2_instance_name, ec2_instance_info in var.ec2_instance_config : ec2_instance_name => {
      ami                         = ec2_instance_info.ami
      instance_type               = ec2_instance_info.instance_type
      security_group_name         = ec2_instance_info.security_group_name
      subnet_name                 = ec2_instance_info.subnet_name
      availability_zone           = ec2_instance_info.availability_zone
      associate_public_ip_address = coalesce(ec2_instance_info.associate_public_ip_address, false)
      availability_zone           = ec2_instance_info.availability_zone
    }
  }
}

module "ec2" {
  source     = "src"

  ## EC2 instance configuration
  ec2_instance_config = local.ec2_instance_config
}
```

The following example TFVars can be used with this module.

```hcl
ec2_instance_config = {
  "bastion-dev1" = {
    ami                         = "ami-07355fe79b493752d"
    instance_type               = "t2.micro"
    subnet_name                 = "public1-dev1"
    security_group_name         = ["bastion-dev1"]
    availability_zone           = "eu-west-1a"
    associate_public_ip_address = true
    tags = {
      "Name" = "bastion-dev1"
    }
  }
  "private-ec2-dev1" = {
    ami                 = "ami-07355fe79b493752d"
    instance_type       = "t2.micro"
    subnet_name         = "private1-dev1"
    security_group_name = ["private-dev1"]
    availability_zone   = "eu-west-1a"
    tags = {
      "Name" = "private-ssh-dev1"
    }
  }
}
```