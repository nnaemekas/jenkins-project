resource "aws_default_vpc" "default"{
 tags = {
    Name = "Default VPC"
 }
} 

data "aws_availability_zones" "available" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for us-east-2a"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow 8080 & 22 inbound traffic"
  vpc_id      = aws_default_vpc.default.id

ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

ingress {
    description      = "http access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
}

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "jenkins_server" {
    ami   = "ami-0ab0629dba5ae551d"
    instance_type = "t2.micro"
    subnet_id =  aws_default_subnet.default_az1.id
    vpc_security_group_ids = [ aws_security_group.allow_tls.id ]
    key_name = "pythoholic ec2"

    tags ={
        Name = "jenkins_server"
    }
}


resource "null_resource" "name" {
    
    connection {
      type        = "ssh"
      host        = aws_instance.jenkins_server.public_ip
      user        = "ubuntu"
      private_key = file("~/Downloads/pythoholicec2.pem")
   }

 provisioner "file"{
    source = "install_jenkins.sh"
    destination = "~/tmp/install_jenkins.sh"
  }
  provisioner "remote-exec"{
    inline = [
       "sudo chomd +x /tmp/install_jenkins.sh",
       "sh /tmp/install_jenkins.sh"
    ]
  }
    depends_on = [
     aws_instance.jenkins_server
   ]
 
  }
  
