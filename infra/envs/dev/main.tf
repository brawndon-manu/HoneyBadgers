module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  project_name = var.project_name
  env          = var.env
  aws_region   = var.aws_region
}

module "dynamodb" {

  source         = "../../modules/dynamodb"
  ddb_table_name = var.ddb_table_name
  project_name   = var.project_name
  env            = var.env
}

# --- CloudWatch Logs module (dev) ---
module "cw" {
  source = "../../modules/cw"

  project_name     = var.project_name
  env              = var.env
  cw_log_retention = var.cw_log_retention
}


# --- VPC Flow Logs (dev) ---
module "flow_logs" {
  source = "../../modules/flow_logs"

  project_name   = var.project_name
  env            = var.env
  vpc_id         = module.vpc.vpc_id
  log_group_name = module.cw.flowlogs_log_group_name

  # Cost guardrail: start with REJECT only
  traffic_type   = "REJECT"
}
# --- S3 Logs bucket (dev) ---
module "s3_logs" {
  source = "../../modules/s3_logs"

  project_name = var.project_name
  env          = var.env
  aws_region   = var.aws_region

  # Env-level var already defined as log_bucket_name
  logs_bucket_name = var.log_bucket_name

  # Can be overridden via tfvars if needed
  lifecycle_transition_days = 90
  lifecycle_expiration_days = 365
}
