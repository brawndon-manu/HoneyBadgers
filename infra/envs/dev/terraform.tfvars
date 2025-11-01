aws_region       = "us-west-2"
project_name     = "honeybadgers"
env              = "dev"

# networking (replace these with your chosen CIDRs)
vpc_cidr         = "<CIDR e.g. 10.10.0.0/16>"
public_subnets   = ["<CIDR e.g. 10.10.1.0/24>"]
private_subnets  = ["<CIDR e.g. 10.10.2.0/24>"]

# logs & tables (you can keep or change names)
log_bucket_name  = "hb-dev-logs-<uniq>"
cw_log_retention = 90
ddb_table_name   = "ThreatIntelDev"
