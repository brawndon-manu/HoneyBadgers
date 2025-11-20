aws_region   = "us-west-2"
project_name = "honeybadgers"
env          = "dev"

# networking (replace these with your chosen CIDRs)
vpc_cidr        = "10.20.0.0/16"
public_subnets  = ["10.20.1.0/24"]
private_subnets = ["10.20.2.0/24"]

# logs & tables (you can keep or change names)
log_bucket_name  = "hb-dev-logs-manu"
cw_log_retention = 90
ddb_table_name   = "ThreatIntelDev"
