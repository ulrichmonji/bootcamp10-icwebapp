resource "aws_instance" "ic-webapp-ec2" {
  ami               = "ami-0ff8a91507f77f867"
  instance_type     = var.instance_type
  key_name          = var.ssh_key
  availability_zone = var.AZ
  security_groups   = ["${var.sg_name}"]
  tags = {
    Name = "${var.maintainer}-ec2"
  }

  root_block_device {
    delete_on_termination = true
  }

  provisioner "local-exec" {
    command =   "echo -e ansible_host: ${var.public_ip} >> ./sources/ansible-ressources/host_vars/${var.server_name}.yml" 
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo amazon-linux-extras install docker",
      "sudo service docker start",
      "sudo systemctl enable docker",
      "sudo usermod -a -G docker ec2-user"
    ]
    connection {
      type        = "ssh"
      user        = var.user
      private_key = file("./${var.ssh_key}.pem")
      host        = self.public_ip
    }
  }

}

