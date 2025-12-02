output "parser_lambda_name" {
  description = "Name of the parser Lambda function."
  value       = aws_lambda_function.parser.function_name
}

output "parser_lambda_arn" {
  description = "ARN of the parser Lambda function."
  value       = aws_lambda_function.parser.arn
}

output "waf_automation_lambda_name" {
  description = "Name of the WAF automation Lambda function."
  value       = aws_lambda_function.waf_automation.function_name
}

output "waf_automation_lambda_arn" {
  description = "ARN of the WAF automation Lambda function."
  value       = aws_lambda_function.waf_automation.arn
}

output "health_lambda_name" {
  description = "Name of the health check Lambda function."
  value       = aws_lambda_function.health.function_name
}

output "health_lambda_arn" {
  description = "ARN of the health check Lambda function."
  value       = aws_lambda_function.health.arn
}