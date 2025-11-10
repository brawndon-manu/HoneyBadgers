module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  project_name = var.project_name
  env          = var.env
  aws_region   = var.aws_region
}

module "dynamodb_threatintel" {
  source         = "../../modules/dynamodb"
  ddb_table_name = var.ddb_table_name
  project_name   = var.project_name
  env            = var.env
}

