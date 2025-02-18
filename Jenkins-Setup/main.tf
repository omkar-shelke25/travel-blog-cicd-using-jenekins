# Jenkins Master Security Group
resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins-master-sg"
  description = "Security group for Jenkins Master"

  # SSH access (Restrict to your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP
  }

  # Jenkins UI (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins Slave Security Group
resource "aws_security_group" "jenkins_slave_sg" {
  name        = "jenkins-slave-sg"
  description = "Security group for Jenkins Slave"

  # Outbound (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group Rule: Allow Master to communicate with Slave (SSH)
resource "aws_security_group_rule" "master_to_slave_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_slave_sg.id
  source_security_group_id = aws_security_group.jenkins_master_sg.id
}

# Security Group Rule: Allow Master to communicate with Slave (Agent Communication)
resource "aws_security_group_rule" "master_to_slave_agent" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_slave_sg.id
  source_security_group_id = aws_security_group.jenkins_master_sg.id
}

# Security Group Rule: Allow Slave to communicate with Master (Agent Communication)
resource "aws_security_group_rule" "slave_to_master_agent" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_master_sg.id
  source_security_group_id = aws_security_group.jenkins_slave_sg.id
}

# Jenkins Master EC2 Instance
resource "aws_instance" "jenkins_master" {
  ami             = data.aws_ami.image.id  # Replace with latest AMI ID
  instance_type   = "t2.micro"
  key_name        = "jenkins-server"  # Replace with your key pair
  user_data = file("jenkins-install.sh")
  vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]

  tags = {
    Name = "Jenkins-Master"
  }
}

# Jenkins Slave EC2 Instance
resource "aws_instance" "jenkins_slave" {
  ami             = data.aws_ami.image.id  # Replace with latest AMI ID
  instance_type   = "t2.micro"
  key_name        = "jenkins-server" # Replace with your key pair
  user_data = file("jenkins-agent.sh") 
  vpc_security_group_ids = [aws_security_group.jenkins_slave_sg.id]

  tags = {
    Name = "Jenkins-Slave"
  }
}
