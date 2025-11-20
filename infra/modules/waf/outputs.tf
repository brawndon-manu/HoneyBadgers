output "waf_blocked_ipset_arn" {
  description = "ARN of the WAFv2 IPSet used for blocking attacker IPs"
  value       = aws_wafv2_ip_set.blocked_ips.arn
}

output "waf_blocked_ipset_id" {
  description = "ID of the WAFv2 IPSet used for blocking attacker IPs"
  value       = aws_wafv2_ip_set.blocked_ips.id
}