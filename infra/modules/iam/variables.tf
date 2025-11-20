variable "project_name" {
  description = "Project name for tagging and naming IAM resources"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "threatintel_table_arn" {
  description = "ARN of the DynamoDB ThreatIntel table this account uses"
  type        = string
}
