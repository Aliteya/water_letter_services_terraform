locals {
  instance_type = "t3.micro"
  azs_num       = 0
  all_traffic   = "0.0.0.0/0"
}

resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "private_key_pem" {
  name  = "/bastion/ssh_key"
  type  = "SecureString"
  value = tls_private_key.bastion_key.private_key_pem
}

resource "aws_key_pair" "bastion_key" {
  public_key = tls_private_key.bastion_key.public_key_openssh
  key_name   = "bastion-key"
}

resource "aws_security_group" "nat_instance_sg" {
  vpc_id      = var.vpc_id
  description = "Security group for NAT Instance"
  ingress {
    description      = "Ingress CIDR(NAT)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = var.private_subnet_cidrs
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
  }
  ingress {
    description      = "Ingress for SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.ec2_bastion_ingress_ip]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
  }
  egress {
    description      = "Default egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
  }

  tags = {
    Name = "NAT Instance Security Group"
  }
}

resource "aws_network_interface" "network_interface" {
  subnet_id         = var.public_subnet_ids[local.azs_num]
  source_dest_check = false
  security_groups   = [aws_security_group.nat_instance_sg.id]

  tags = {
    Name = "NAT Instance Network Interface"
  }
}

data "aws_ami" "nat_instance_ami" {
  filter {
    name   = "image-id"
    values = ["ami-0437df53acb2bbbfd"]
  }
}

resource "aws_eip" "ec2_bastion_host_eip" {
  domain = "vpc"
  tags = {
    Name = "Elastic IP for Bastion Host"
  }
}

resource "aws_instance" "nat_instance" {
  ami           = data.aws_ami.nat_instance_ami.id
  instance_type = local.instance_type
  key_name      = aws_key_pair.bastion_key.key_name
  network_interface {
    network_interface_id = aws_network_interface.network_interface.id
    device_index         = 0
  }
  user_data = <<-EOF
                    #!/bin/bash
                    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-ip_forward.conf
                    sysctl -p /etc/sysctl.d/99-ip_forward.conf
                    dnf install -y firewalld
                    systemctl enable --now firewalld
                    
                    firewall-cmd --add-masquerade --permanent
                    PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}')

                    firewall-cmd --zone=public --add-interface=$PRIMARY_INTERFACE --permanent
                    firewall-cmd --reload
                EOF
  lifecycle {
    ignore_changes = [
      associate_public_ip_address,
    ]
  }
  tags = {
    Role = "nat"
  }
}

resource "aws_eip_association" "bastion_eip_asso" {
  instance_id   = aws_instance.nat_instance.id
  allocation_id = aws_eip.ec2_bastion_host_eip.id
}