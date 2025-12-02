aws_region   = "us-west-2"
project_name = "honeybadgers"
env          = "dev"
waf_automation_schedule_expression = "rate(5 minutes)"

# networking (replace these with chosen CIDRs)
vpc_cidr        = "10.20.0.0/16"
public_subnets  = ["10.20.1.0/24"]
private_subnets = ["10.20.2.0/24"]

log_bucket_name  = "hb-dev-logs-manu"
cw_log_retention = 90
ddb_table_name   = "ThreatIntelDev"
