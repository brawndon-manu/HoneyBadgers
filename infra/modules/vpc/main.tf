terraform {
  required_providers { aws = { source = "hashicorp/aws" } }
}

data "aws_availability_zones" "available" { state = "available" }

locals { azs = data.aws_availability_zones.available.names }

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-vpc" })
}

resource "aws_subnet" "public" {
  for_each                = { for i, cidr in var.public_subnets : i => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = local.azs[each.key % length(local.azs)]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-public-${each.key}", Tier = "public" })
}

resource "aws_subnet" "private" {
  for_each                  = { for i, cidr in var.private_subnets : i => cidr }
  vpc_id                    = aws_vpc.this.id
  cidr_block                = each.value
  availability_zone         = local.azs[each.key % length(local.azs)]
  map_public_ip_on_launch   = false
  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-private-${each.key}", Tier = "private" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
