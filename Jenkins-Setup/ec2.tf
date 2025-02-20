resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.image.id # Replace with latest AMI ID
  instance_type          = "t2.medium"
  key_name               = "jenkins-login" # Replace with your key pair
  vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]

  tags = {
    Name = "Jenkins-Master"
  }

  root_block_device {
    volume_size           = 15  # Set the root volume size (in GB)
    volume_type           = "gp3"  # gp2, gp3, io1, io2, standard, sc1, st1
    delete_on_termination = true  # Delete volume when instance is terminated
    encrypted             = true  # Encrypt the root volume
  }

  # Install Jenkins and SonarQube via remote-exec
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("jenkins-login.pem")
      host        = self.public_ip
    }

    inline = [
      "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install java -y",
      "sudo yum install -y jenkins",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now jenkins",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      
      #"sudo usermod -aG docker ec2-user",
      #"newgrp docker", # Apply the group change immediately
      #"docker ps", # Forces session reload to apply group change

      #"docker run -itd --name SonarQube-Server -p 9000:9000 sonarqube:lts-community"
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("jenkins-login.pem")
      host        = self.public_ip
    }

    inline = [
      "sleep 30", # Wait for Jenkins to start
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /tmp/jenkins_admin_password",
      "chmod 644 /tmp/jenkins_admin_password"
    ]
  }
}

# Jenkins Slave EC2 Instance
resource "aws_instance" "jenkins_slave" {
  ami                    = data.aws_ami.image.id # Replace with latest AMI ID
  instance_type          = "t2.medium"
  key_name               = "jenkins-login" # Replace with your key pair
  vpc_security_group_ids = [aws_security_group.jenkins_slave_sg.id]

  tags = {
    Name = "Jenkins-Slave"
  }
root_block_device {
    volume_size           = 10  # Set the root volume size (in GB)
    volume_type           = "gp3"  # gp2, gp3, io1, io2, standard, sc1, st1
    delete_on_termination = true  # Delete volume when instance is terminated
    encrypted             = true  # Encrypt the root volume
  }
  # Install Docker and Trivy on Jenkins worker
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("jenkins-login.pem")
      host        = self.public_ip
    }

    inline = [
      "sudo yum update -y",
      "sudo yum install java -y",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo yum install -y wget",
      "cat << EOF | sudo tee -a /etc/yum.repos.d/trivy.repo",
      "[trivy]",
      "name=Trivy repository",
      "baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\\$basearch/",
      "gpgcheck=1",
      "enabled=1",
      "gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key",
      "EOF",
      "sudo yum -y update",
      "sudo yum -y install trivy"
    ]
  }
}
