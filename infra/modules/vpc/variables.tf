variable "vpc_cidr"       { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets"{ type = list(string) }

variable "project_name" { type = string }
variable "env"          { type = string }
variable "aws_region"   { type = string }

locals {
  common_tags = {
    Project = var.project_name
    Env     = var.env
  }
}
