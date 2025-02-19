output "jenkins_master_public_ip" {
  description = "Public IP of the Jenkins Master instance"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_slave_public_ip" {
  description = "Public IP of the Jenkins Slave instance"
  value       = aws_instance.jenkins_slave.public_ip
}

output "jenkins_master_url" {
  description = "Jenkins Web Interface URL"
  value       = "http://${aws_instance.jenkins_master.public_ip}:8080"
}

output "jenkins_initial_admin_password" {
  description = "Jenkins Initial Admin Password"
  value       = <<EOT
  Run the following command to get the password:
  ssh -i jenkins-login.pem ec2-user@${aws_instance.jenkins_master.public_ip} "cat /tmp/jenkins_admin_password"
  EOT
}

output "ssh_command_master" {
  description = "SSH command to connect to the Jenkins Master instance"
  value       = "ssh -i jenkins-login.pem ec2-user@${aws_instance.jenkins_master.public_ip}"
}

output "ssh_command_slave" {
  description = "SSH command to connect to the Jenkins Slave instance"
  value       = "ssh -i jenkins-login.pem ec2-user@${aws_instance.jenkins_slave.public_ip}"
}
