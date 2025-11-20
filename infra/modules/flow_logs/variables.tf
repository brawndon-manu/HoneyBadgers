variable "project_name" {
  type        = string
  description = "Project name tag/prefix."
}

variable "env" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC to capture flow logs for."
}

variable "log_group_name" {
  type        = string
  description = "Existing CloudWatch Log Group name to send VPC Flow Logs to."
}

variable "traffic_type" {
  type        = string
  description = "Type of traffic to log (ACCEPT, REJECT, ALL)."
  default     = "REJECT"
}
