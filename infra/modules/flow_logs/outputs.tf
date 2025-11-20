output "flow_log_id" {
  description = "ID of the VPC Flow Log."
  value       = aws_flow_log.vpc.id
}

output "flow_log_iam_role_arn" {
  description = "ARN of the IAM role used by VPC Flow Logs."
  value       = aws_iam_role.flow_logs.arn
}

output "flow_log_iam_role_name" {
  description = "Name of the IAM role used by VPC Flow Logs."
  value       = aws_iam_role.flow_logs.name
}
