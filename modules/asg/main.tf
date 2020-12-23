resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role.reads3role.name
}

resource "aws_iam_role" "reads3role" {
  name = "reads3role-${terraform.workspace}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
    EOF
}

resource "aws_iam_policy" "reads3_policy" {
  name        = "reads3-policy-${terraform.workspace}"
  description = "S3 read policy"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": [
            "s3:GetObject",
            "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Resource": [ "arn:aws:s3:::mehdi-php-app/*",
                      "arn:aws:s3:::mehdi-php-app"
          ]
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.reads3role.name
  policy_arn = aws_iam_policy.reads3_policy.arn
}

resource "aws_launch_configuration" "as_conf" {
  depends_on           = [aws_iam_instance_profile.instance_profile]
  key_name             = var.key_name
  name_prefix          = "mehdi-launch-config-${terraform.workspace}"
  image_id             = "ami-09558250a3419e7d0"
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.asg_sg.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.id
  user_data            = <<EOF
    #!/bin/bash
    set -x
    yum update -y
    amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    groupadd www
    usermod -a -G www ec2-user
    chgrp -R www /var/www
    chmod 2775 /var/www
    find /var/www -type d -exec sudo chmod 2775 {} +
    find /var/www -type f -exec sudo chmod 0664 {} +
    cd /var/www/html
    aws s3 cp s3://mehdi-php-app/loginsystem/ . --recursive
    sed -i "s/localhost/${var.clb_dns}/g" dbconnection.php
    sed -i "s/''/'CODE8mate\*'/g" dbconnection.php
    EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "asg-mehdi-${terraform.workspace}"
  launch_configuration = aws_launch_configuration.as_conf.name
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size
  vpc_zone_identifier  = var.private_subnet
  target_group_arns    = [var.alb_tg]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "asg-${terraform.workspace}"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "asg_sg" {
  name        = "asg-sg-${terraform.workspace}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "inbound for alb"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_sg]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asg-sg-${terraform.workspace}"
  }
}