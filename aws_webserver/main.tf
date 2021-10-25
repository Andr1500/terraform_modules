data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_subnet" "web" { #get VPC ID
  id = var.subnet_id
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id # Amazon Linux2
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id]
  subnet_id              = var.subnet_id
  user_data              = <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<HTMLTEXT > /var/www/html/index.html
<h2>
${var.name} WebServer with IP: $myip <br>
${var.name} Webserver in AZ: ${data.aws_subnet.web.availability_zone} <br>
Message: </h2> ${var.message}
HTMLTEXT

service httpd start
chkconfig httpd on
EOF
  tags = {
    Name  = "${var.name}-Webserver-${var.subnet_id}"
    Owner = "a1500"
  }
}

resource "aws_security_group" "webserver" {
  name_prefix = "${var.name} WebServer SG-"
  vpc_id      = data.aws_subnet.web.vpc_id
  description = "Security Group for my WebServer"

  ingress {
    description = "Allow port HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow ALL ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.name}-web-server-sg"
    Owner = "a1500"
  }
}
