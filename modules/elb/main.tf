resource "aws_elb" "internal_lb" {
  name            = "mehdi-clb-${terraform.workspace}"
  subnets         = var.private_subnet
  internal        = true
  security_groups = [aws_security_group.clb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 3306
    instance_protocol = "tcp"
    lb_port           = 3306
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:3306"
    interval            = 30
  }

  instances                   = [var.sql_id]
  cross_zone_load_balancing   = true
  idle_timeout                = 600
  connection_draining         = true
  connection_draining_timeout = 600
}

resource "aws_security_group" "clb_sg" {
  name        = "clb-sg-${terraform.workspace}"
  description = "Allow autoscaling group servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "inbound for asg"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.asgsg]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}