output "parser_lambda_role_arn" {
  description = "IAM role ARN for the parser Lambda function"
  value       = aws_iam_role.parser_lambda_role.arn
}

output "parser_lambda_role_name" {
  description = "IAM role name for the parser Lambda function"
  value       = aws_iam_role.parser_lambda_role.name
}

output "waf_lambda_role_arn" {
  description = "IAM role ARN for the WAF automation Lambda function"
  value       = aws_iam_role.waf_lambda_role.arn
}

output "waf_lambda_role_name" {
  description = "IAM role name for the WAF automation Lambda function"
  value       = aws_iam_role.waf_lambda_role.name
}
