<<<<<<< HEAD
﻿output "flowlogs_log_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.flowlogs.name
}

output "flowlogs_log_group_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.flowlogs.arn
}

output "events_log_group_name" {
  description = "Name of the events CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.events.name
}

output "events_log_group_arn" {
  description = "ARN of the events CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.events.arn
}
=======
output "events_log_group_name" {
  value = aws_cloudwatch_log_group.events.name
}

output "events_log_group_arn" {
  value = aws_cloudwatch_log_group.events.arn
}

output "flowlogs_log_group_name" {
  value = aws_cloudwatch_log_group.flowlogs.name
}

output "flowlogs_log_group_arn" {
  value = aws_cloudwatch_log_group.flowlogs.arn
}
>>>>>>> abec886 (chore(cw): expose events/flowlogs log group outputs)
