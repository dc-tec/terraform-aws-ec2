variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "ec2_instance_config" {
  description = "EC2 instance configuration"
  type = map(object({
    ami                         = string
    instance_type               = string
    security_group_name         = list(string)
    subnet_name                 = string
    availability_zone           = string
    associate_public_ip_address = optional(bool, false)
    availability_zone           = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    environment = "Dev"
    managedBy   = "Terraform"
    owner       = "RoelC"
  }
}