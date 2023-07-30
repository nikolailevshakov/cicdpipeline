output "jenkins_instance" {
  description = "Public IP of instance"
  value = aws_instance.jenkins.public_ip
}

output "dev_instance" {
  description = "Public IP of instance"
  value = aws_instance.dev-server.public_ip
}

output "prod_instance" {
  description = "Public IP of instance"
  value = aws_instance.prod-server.public_ip
}

output "monitoring_instance" {
  description = "Public IP of instance"
  value = aws_instance.monitoring-server.public_ip
}

