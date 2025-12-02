output "rest_api_id" {
  description = "ID of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_arn" {
  description = "ARN of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.this.arn
}

output "stage_name" {
  description = "Deployed API Gateway stage name."
  value       = aws_api_gateway_stage.this.stage_name
}

output "invoke_url" {
  description = "Base invoke URL for the API Gateway stage."
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}"
}