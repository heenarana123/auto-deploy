provider "aws" {
  region     = "ap-south-1"
}

variable "use_existing_sg_id" {
  type    = string
  default = ""
}

data "aws_security_groups" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["allow_ssh_http"]
  }
}

resource "aws_security_group" "new_sg" {
  count       = length(data.aws_security_groups.existing_sg.ids) == 0 ? 1 : 0
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  security_group_id = length(data.aws_security_groups.existing_sg.ids) > 0 ?data.aws_security_groups.existing_sg.ids[0] :aws_security_group.new_sg[0].id
}

resource "aws_instance" "Auto_Deploy_Website" {
  ami           = "ami-00bb6a80f01f03502"
  instance_type = "t2.micro"
  key_name      = "mihir"

  vpc_security_group_ids = [local.security_group_id]

  tags = {
    Name = "Auto_Deploy_Website"
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "[web]" > ../ansible-setup/inventory
      echo "nginx-server ansible_host=${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/mihir.pem" >> ../ansible-setup/inventory
    EOT
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ami]
  }
}

output "instance_ip" {
  value = aws_instance.Auto_Deploy_Website.public_ip
}
