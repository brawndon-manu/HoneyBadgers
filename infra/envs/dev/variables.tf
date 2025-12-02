variable "aws_region" {
  description = "AWS region for this environment"
  type        = string
}

variable "project_name" {
  description = "Base name used for tagging and resource naming"
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "log_bucket_name" {
  description = "Name of the central logs S3 bucket"
  type        = string
}

variable "cw_log_retention" {
  description = "CloudWatch Logs retention period in days"
  type        = number
}

variable "ddb_table_name" {
  description = "Name of the DynamoDB ThreatIntel table"
  type        = string
}

variable "waf_automation_schedule_expression" {
  description = "Schedule expression (rate or cron) for the WAF automation Lambda (e.g., rate(5 minutes))"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use for this environment"
  type        = string
}
