output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_eip.web.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.web.private_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.web.public_dns
}

output "website_url" {
  description = "URL of the deployed website"
  value       = "http://${aws_eip.web.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.project_name}-deployer-key.pem ec2-user@${aws_eip.web.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.deployer.key_name
}
