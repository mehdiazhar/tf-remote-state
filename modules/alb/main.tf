resource "aws_alb" "alb" {
  name               = "alb-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_tg.arn
  }
}

resource "aws_alb_target_group" "alb_tg" {
  name     = "alb-tg-${terraform.workspace}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name = "alb-tg-${terraform.workspace}"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${terraform.workspace}"
  description = "Allow internet traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "inbound for internet traffic"
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
  tags = {
    Name = "alb-sg"
  }
}