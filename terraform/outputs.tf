output "Private_IPv4_addresses_public_instance_syslog_ng_0" {
  value       = aws_instance.public_test[0].private_ip
  description = "Syslog NG 0 private IP"
}

output "Private_IPv4_addresses_public_instance_syslog_ng_1" {
  value       = aws_instance.public_test[1].private_ip
  description = "Syslog NG 1 private IP"
}

output "Private_IPv4_addresses_public_instance_dns_server" {
  value       = aws_instance.public_test[2].private_ip
  description = "DNS server private IP"
}

output "Private_IPv4_addresses_public_instance_client" {
  value       = aws_instance.public_test[3].private_ip
  description = "client private IP"
}

output "Private_IPv4_addresses_public_instance_mirror" {
  value       = aws_instance.public_test[4].private_ip
  description = "mirror private IP"
}

output "Public_IPv4_DNS_syslog_ng_0" {
  value = aws_instance.public_test[0].public_dns
}

output "Public_IPv4_DNS_syslog_ng_1" {
  value = aws_instance.public_test[1].public_dns
}

output "Public_IPv4_DNS_dns_server" {
  value = aws_instance.public_test[2].public_dns
}

output "Public_IPv4_DNS_client" {
  value = aws_instance.public_test[3].public_dns
}

output "Public_IPv4_mirror_relay" {
  value = aws_instance.public_test[4].public_dns
}
