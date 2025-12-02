variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "env" { type = string }

variable "vpc_cidr" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

variable "log_bucket_name" { type = string }
variable "cw_log_retention" { type = number }
variable "ddb_table_name" { type = string }

variable "waf_automation_schedule_expression" {
  description = "Schedule expression (rate or cron) for the WAF automation Lambda (e.g., rate(5 minutes))"
  type        = string
}