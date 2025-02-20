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
    description = "Allow SSH access to Jenkins Master"
  }

  # Jenkins UI (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Jenkins UI"
  }

  # Outbound (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
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
    description = "Allow all outbound traffic"
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
  description              = "Allow Jenkins Master to SSH into Slave"
}

# Security Group Rule: Allow Master to communicate with Slave (Agent Communication)
resource "aws_security_group_rule" "master_to_slave_agent" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_slave_sg.id
  source_security_group_id = aws_security_group.jenkins_master_sg.id
  description              = "Allow Jenkins Master to communicate with Slave agent"
}

# Security Group Rule: Allow Slave to communicate with Master (Agent Communication)
resource "aws_security_group_rule" "slave_to_master_agent" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_master_sg.id
  source_security_group_id = aws_security_group.jenkins_slave_sg.id
  description              = "Allow Jenkins Slave to communicate with Master agent"
}

# Add SSH access for Jenkins Slave (replace 0.0.0.0/0 with your IP)
resource "aws_security_group_rule" "allow_ssh_slave" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_slave_sg.id
  cidr_blocks       = ["0.0.0.0/0"] # ⚠️ Replace with your IP for security
  description       = "Allow SSH access to Jenkins Slave"
}

# Kubernetes Node Port Rules
resource "aws_security_group_rule" "kubernetes_node_ports" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP traffic"
}

resource "aws_security_group_rule" "kubernetes_node_ports_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS traffic"
}

resource "aws_security_group_rule" "kubernetes_node_ports_redis" {
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow Redis traffic"
}

resource "aws_security_group_rule" "kubernetes_node_ports_smtp" {
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SMTP traffic"
}

resource "aws_security_group_rule" "kubernetes_node_ports_smtps" {
  type              = "ingress"
  from_port         = 465
  to_port           = 465
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SMTPS traffic"
}

resource "aws_security_group_rule" "kubernetes_node_ports_range" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 10000
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow NodePort range traffic"
}

resource "aws_security_group_rule" "kubernetes_apiserver" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_master_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow Kubernetes API Server traffic"
}




