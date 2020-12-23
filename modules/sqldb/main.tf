resource "aws_instance" "sqldb" {
  ami             = var.sqldbinstance
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = element(var.private_subnet, 0)
  security_groups = [aws_security_group.sql_sg.id]
  user_data       = <<EOF
  #!/bin/bash

  yum update -y
  yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm -y
  yum install -y mysql-community-server
  systemctl enable mysqld
  systemctl start mysqld

  mysql -u root "-p$(grep -oP '(?<=root@localhost\: )\S+' /var/log/mysqld.log)" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'CODE8mate*'" --connect-expired-password

  mysql -u root "-pCODE8mate*" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'CODE8mate*';FLUSH PRIVILEGES;CREATE DATABASE loginsystem;USE loginsystem;CREATE TABLE \`users\` (\`id\` int(11) NOT NULL,\`fname\` varchar(255) DEFAULT NULL,\`lname\` varchar(255) DEFAULT NULL,\`email\` varchar(255) DEFAULT NULL,\`password\` varchar(300) DEFAULT NULL,\`contactno\` varchar(11) DEFAULT NULL,\`posting_date\` timestamp NOT NULL DEFAULT current_timestamp()) ENGINE=InnoDB DEFAULT CHARSET=latin1;ALTER TABLE \`users\` ADD PRIMARY KEY (\`id\`);ALTER TABLE \`users\` MODIFY \`id\` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;COMMIT;"

  service mysqld restart
  chkconfig mysqld on
  
  EOF

  tags = {
    Name = "sql-${terraform.workspace}"
  }
}

resource "aws_security_group" "sql_sg" {
  name        = "sql-sg-${terraform.workspace}"
  description = "Allow elb"
  vpc_id      = var.vpc_id

  ingress {
    description     = "inbound for elb"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.clb_sg]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}