terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
  }
}

# configure provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "week18" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "week18"
  }
}

# Create 2 Public Subnets
resource "aws_subnet" "public_subnet1a_week18" {
  vpc_id            = aws_vpc.week18.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public subnet 1a_week18"
  }
}

resource "aws_subnet" "public_subnet1b_week18" {
  vpc_id            = aws_vpc.week18.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public subnet 1b_week18"
  }
}

# Create 2 Private Subnets
resource "aws_subnet" "private_subnet_1a_week18" {
  vpc_id                  = aws_vpc.week18.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private subnet 1a_week18"
  }
}
resource "aws_subnet" "private_subnet_1b_week18" {
  vpc_id                  = aws_vpc.week18.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private subnet 1b_week18"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "ig_week18" {
  tags = {
    Name = "internet_gateway_week18"
  }
  vpc_id = aws_vpc.week18.id
}

# Create Route Table
resource "aws_route_table" "route_table_week18" {
  tags = {
    Name = "route_table_week18"
  }
  vpc_id = aws_vpc.week18.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_week18.id
  }
}

# Create Route Table Association
resource "aws_route_table_association" "route_table_association1_week18" {
  subnet_id      = aws_subnet.public_subnet1a_week18.id
  route_table_id = aws_route_table.route_table_week18.id
}

resource "aws_route_table_association" "route_table_association2_week18" {
  subnet_id      = aws_subnet.public_subnet1b_week18.id
  route_table_id = aws_route_table.route_table_week18.id
}

# Create VPC Security Groups
resource "aws_security_group" "publicsg_week18" {
  name        = "publicsg_week18"
  description = "Allow traffic from VPC"
  vpc_id      = aws_vpc.week18.id
  depends_on = [
    aws_vpc.week18
  ]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
  }
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPC_week18"
  }
}

# Create security group for load balancer
resource "aws_security_group" "alb_sg_week18" {
  name        = "alb_sg_week18"
  description = "security group for the load balancer"
  vpc_id      = aws_vpc.week18.id
  depends_on = [
    aws_vpc.week18
  ]


  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "alb_sg_week18"
  }
}

# Create EC2 instance for public subnet 1
resource "aws_instance" "web_server1_week18" {
  ami             = "ami-026b57f3c383c2eec"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.publicsg_week18.id]
  subnet_id       = aws_subnet.public_subnet1a_week18.id

  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start
        systemctl enable
        echo '<h1>Aloha!</h1>' > /usr/share/nginx/html/index.html
        EOF
}

# Create EC2 instance for public subnet 2
resource "aws_instance" "web_server2_week18" {
  ami             = "ami-026b57f3c383c2eec"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.publicsg_week18.id]
  subnet_id       = aws_subnet.public_subnet1b_week18.id

  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start
        systemctl enable 
        echo '<h1>Hey yall!</h1>' > /usr/share/nginx/html/index.html
        EOF
}
# Create Load balancer
resource "aws_lb" "lb_week18" {
  name               = "lb-week18"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.publicsg_week18.id]
  subnets            = [aws_subnet.public_subnet1a_week18.id, aws_subnet.public_subnet1b_week18.id]

  tags = {
    Environment = "week18"
  }
}

resource "aws_lb_target_group" "week18_target_grp" {
  name     = "project-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.week18.id
}

# Create ALB listener
resource "aws_lb_listener" "alb_week18" {
  load_balancer_arn = aws_lb.lb_week18.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target.arn
  }
}

#target group
resource "aws_lb_target_group" "lb_target" {
  name       = "target"
  depends_on = [aws_vpc.week18]
  port       = "80"
  protocol   = "HTTP"
  vpc_id     = aws_vpc.week18.id
  health_check {
    interval            = 70
    path                = "/var/www/html/index.html"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}
resource "aws_lb_target_group_attachment" "acquire_targets_mki" {
  target_group_arn = aws_lb_target_group.lb_target.arn
  target_id        = aws_instance.web_server1_week18.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "acquire_targets_mkii" {
  target_group_arn = aws_lb_target_group.lb_target.arn
  target_id        = aws_instance.web_server2_week18.id
  port             = 80
}
# Database subnet group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "db_subnet"
  subnet_ids = [aws_subnet.private_subnet_1a_week18.id, aws_subnet.private_subnet_1b_week18.id]
}
# Security group for database tier
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "allow traffic only from web_sg"
  vpc_id      = aws_vpc.week18.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.publicsg_week18.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.publicsg_week18.id]
    cidr_blocks     = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Database instance in private subnet 1
resource "aws_db_instance" "db1" {
  allocated_storage           = 5
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t2.micro"
  db_subnet_group_name        = "db_subnet"
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  parameter_group_name        = "default.mysql5.7"
  db_name                     = "db_week18"
  username                    = "admin"
  password                    = "password"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 35
  backup_window               = "22:00-23:00"
  maintenance_window          = "Sat:00:00-Sat:03:00"
  multi_az                    = false
  skip_final_snapshot         = true
}