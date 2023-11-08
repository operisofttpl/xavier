# Provider Configuration
provider "aws" {
  region = "ap-south-1"  # Replace with your desired AWS region
}
 
# Security Group Configuration
resource "aws_security_group" "master" {
  name = "master-security-group"
  vpc_id = "vpc-0d9a1c5831c65f653"
 
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # RDP access
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Open to all
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# Private Key Configuration
resource "tls_private_key" "master-key-gen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
 
# Key Pair Configuration
resource "aws_key_pair" "master-key-pair" {
  key_name   = var.keypair_name
  public_key = tls_private_key.master-key-gen.public_key_openssh
}
 
# Kali Linux Instance Configuration
resource "aws_instance" "kali_server" {
  ami           = "ami-037a1c3dbe88d5d11"  # Replace with your desired AMI ID
  instance_type = "t3a.2xlarge"  # Replace with your desired instance type
  key_name      = aws_key_pair.master-key-pair.key_name
  subnet_id = "subnet-0f08400e16b0f52aa"
  availability_zone = "ap-south-1a"
  security_groups = [aws_security_group.master.id]
  tags = {
    Name = var.instance_name1
  }
 
  user_data = <<-EOF
    #!/bin/bash
    cd /home/kali
    sudo chmod +x xfce.sh
    sudo ./xfce.sh
    sudo apt install -y dbus-x11
    sudo systemctl enable xrdp --now
    echo 'kali:kali' | sudo chpasswd
  EOF
}
 
# Exploitable Windows Instance Configuration
resource "aws_instance" "Windows-10-Pro" {
  ami           = "ami-04fc64393c170125d"  # Replace with your desired AMI ID
  instance_type = "t3.medium"  # Replace with your desired instance type
  key_name      = aws_key_pair.master-key-pair.key_name
  subnet_id = "subnet-0f08400e16b0f52aa"
  availability_zone = "ap-south-1a"
 
  security_groups = [aws_security_group.master.id]
 
  tags = {
    Name = var.instance_name3
  }
}
 
# Local Key Pair File Configuration
resource "local_file" "local_key_pair" {
  filename = "${var.keypair_name}.pem"
  file_permission = "0400"
  content = tls_private_key.master-key-gen.private_key_pem
}
 
# Output Configuration
output "pem_file_for_ssh" {
  value     = tls_private_key.master-key-gen.private_key_pem
  sensitive = true
}
 
output "kali_server" {
  value = aws_instance.kali_server.private_ip
}
 
output "exploitable_Windows" {
  value = aws_instance.Windows-10-Pro.private_ip
}
 
output "exploitable_Windows_Username" {
  value = "Administrator"
}
 
output "exploitable_Windows_Password" {
  value = "password@123"
}
 
output "note" {
  value = "If unable to perform SSH, please wait for some time and try again. \nssh -i path-of-pemfile.pem -N -L 3390:127.0.0.1:3390 kali@[kali_server ip] \nNow connect RDP with 127.0.0.1:3390"
}
