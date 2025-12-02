variable "project_name" {
  type        = string
  description = "Project name prefix for API resources."
}

variable "env" {
  type        = string
  description = "Environment name."
}

variable "aws_region" {
  type        = string
  description = "AWS region for the API."
}

variable "api_stage_name" {
  type        = string
  description = "API Gateway stage name."
  default     = "dev"
}

variable "health_lambda_arn" {
  type        = string
  description = "Lambda ARN used for the /health endpoint."
}