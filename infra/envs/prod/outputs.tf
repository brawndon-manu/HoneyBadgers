# --- VPC ---
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = module.vpc.public_route_table_id
}

output "igw_id" {
  description = "ID of the internet gateway."
  value       = module.vpc.igw_id
}

# --- DynamoDB ThreatIntel ---
output "threatintel_table_name" {
  description = "DynamoDB ThreatIntel table name."
  value       = module.dynamodb.table_name
}

output "threatintel_table_arn" {
  description = "DynamoDB ThreatIntel table ARN."
  value       = module.dynamodb.table_arn
}

# --- CloudWatch Logs ---
output "cw_events_log_group_name" {
  description = "CloudWatch log group name for honeypot events."
  value       = module.cw.events_log_group_name
}

output "cw_events_log_group_arn" {
  description = "CloudWatch log group ARN for honeypot events."
  value       = module.cw.events_log_group_arn
}

output "cw_flowlogs_log_group_name" {
  description = "CloudWatch log group name for VPC flow logs."
  value       = module.cw.flowlogs_log_group_name
}

output "cw_flowlogs_log_group_arn" {
  description = "CloudWatch log group ARN for VPC flow logs."
  value       = module.cw.flowlogs_log_group_arn
}

# --- S3 Logs bucket ---
output "logs_bucket_name" {
  description = "Name of the S3 logs bucket."
  value       = module.s3_logs.logs_bucket_name
}

output "logs_bucket_arn" {
  description = "ARN of the S3 logs bucket."
  value       = module.s3_logs.logs_bucket_arn
}

# --- WAF (blocked IP set) ---
output "waf_blocked_ipset_id" {
  description = "ID of the WAFv2 blocked IP set."
  value       = module.waf.waf_blocked_ipset_id
}

output "waf_blocked_ipset_arn" {
  description = "ARN of the WAFv2 blocked IP set."
  value       = module.waf.waf_blocked_ipset_arn
}

# --- Lambda functions ---
output "parser_lambda_name" {
  description = "Name of the parser Lambda function."
  value       = module.lambdas.parser_lambda_name
}

output "parser_lambda_arn" {
  description = "ARN of the parser Lambda function."
  value       = module.lambdas.parser_lambda_arn
}

output "waf_automation_lambda_name" {
  description = "Name of the WAF automation Lambda function."
  value       = module.lambdas.waf_automation_lambda_name
}

output "waf_automation_lambda_arn" {
  description = "ARN of the WAF automation Lambda function."
  value       = module.lambdas.waf_automation_lambda_arn
}

output "health_lambda_name" {
  description = "Name of the health check Lambda function."
  value       = module.lambdas.health_lambda_name
}

output "health_lambda_arn" {
  description = "ARN of the health check Lambda function."
  value       = module.lambdas.health_lambda_arn
}

# --- API Gateway ---
output "api_rest_api_id" {
  description = "ID of the API Gateway REST API."
  value       = module.apigw.rest_api_id
}

output "api_rest_api_arn" {
  description = "ARN of the API Gateway REST API."
  value       = module.apigw.rest_api_arn
}

output "api_stage_name" {
  description = "Deployed API Gateway stage name."
  value       = module.apigw.stage_name
}

output "api_invoke_url" {
  description = "Base invoke URL for the API Gateway stage."
  value       = module.apigw.invoke_url
}