locals {
  common_tags = {
    Project = var.project_name
    Env     = var.env
  }
}

# WAFv2 IPSet for blocked attacker IPs (regional for ALB/API Gateway etc.)
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "${var.project_name}-${var.env}-blocked-ips"
  description        = "HoneyBadgers blocked attacker IPs"
  scope              = "REGIONAL"         # using regional WAF for now
  ip_address_version = "IPV4"

  # Start empty; WAF automation Lambda will update this
  addresses = []

  tags = local.common_tags
}
