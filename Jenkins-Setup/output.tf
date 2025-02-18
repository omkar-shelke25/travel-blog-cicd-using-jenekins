output "jenkins_master_public_ip" {
  description = "Public IP of the Jenkins Master instance"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_slave_public_ip" {
  description = "Public IP of the Jenkins Slave instance"
  value       = aws_instance.jenkins_slave.public_ip
}



