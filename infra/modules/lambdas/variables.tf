variable "project_name" {
  description = "Project name for tagging/naming Lambda resources"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where Lambdas will be deployed"
  type        = string
}

variable "parser_lambda_role_arn" {
  description = "IAM role ARN for the parser Lambda function"
  type        = string
}

variable "threatintel_table_name" {
  description = "Name of the DynamoDB ThreatIntel table"
  type        = string
}

variable "events_log_group_name" {
  description = "CloudWatch log group name for honeypot events"
  type        = string
}

variable "events_log_group_arn" {
  description = "CloudWatch log group ARN for honeypot events"
  type        = string
}

variable "waf_lambda_role_arn" {
  description = "IAM role ARN for the WAF automation Lambda function"
  type        = string
}

variable "waf_ipset_id" {
  description = "ID of the WAFv2 IPSet used for blocking attacker IPs"
  type        = string
}

variable "waf_ipset_arn" {
  description = "ARN of the WAFv2 IPSet used for blocking attacker IPs"
  type        = string
}

variable "waf_automation_schedule_expression" {
  description = "Schedule expression (rate or cron) for the WAF automation Lambda (e.g., rate(5 minutes))"
  type        = string
}
