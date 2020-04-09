# Configure the AWS Provider
provider "aws" {
  region  = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "${var.cidr_block}"
}

#Create IGW
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "IGW"
  }
}

#Create EIP
resource "aws_eip" "elastic_IP" {
  vpc      = true
}


resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.elastic_IP.id}"
  subnet_id     = "${aws_subnet.subnet_public2.id}"

  tags = {
    Name = "NAT"
  }
}

#Create route table public
resource "aws_route_table" "route_table_public" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags = {
    Name = "route_table_public"
  }
}

# Create route table private

resource "aws_default_route_table" "route_table_private" {
  default_route_table_id = "${aws_vpc.myvpc.default_route_table_id}"

  tags = {
    Name = "route-table-private"
  }
}

# create subnet
resource "aws_subnet" "subnet_public1" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone = "${var.az1}"

  tags = {
    Name = "subnet_public1"
  }
}

resource "aws_subnet" "subnet_public2" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone = "${var.az2}"

  tags = {
    Name = "subnet_public2"
  }
}

resource "aws_subnet" "subnet_public3" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "${var.cidrs["public3"]}"
  map_public_ip_on_launch = true
  availability_zone = "${var.az3}"

  tags = {
    Name = "subnet_public3"
  }
}

resource "aws_subnet" "subnet_private1" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone = "${var.az1}"

  tags = {
    Name = "subnet_private1"
  }
}

resource "aws_subnet" "subnet_private2" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "${var.cidrs["private2_rds"]}"
  map_public_ip_on_launch = false
  availability_zone = "${var.az2}"

  tags = {
    Name = "subnet_private2"
  }
}

resource "aws_subnet" "subnet_private3" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "${var.cidrs["private3_rds"]}"
  map_public_ip_on_launch = false
  availability_zone = "${var.az3}"

  tags = {
    Name = "subnet_private3"
  }
}

#subnet group for database
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main-db"
  subnet_ids = ["${aws_subnet.subnet_private1.id}", "${aws_subnet.subnet_private2.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

#Create route association
resource "aws_route_table_association" "rt_association_public1" {
  subnet_id      = "${aws_subnet.subnet_public1.id}"
  route_table_id = "${aws_route_table.route_table_public.id}"
}

resource "aws_route_table_association" "rt_association_public2" {
  subnet_id      = "${aws_subnet.subnet_public2.id}"
  route_table_id = "${aws_route_table.route_table_public.id}"
}

resource "aws_route_table_association" "rt_association_public3" {
  subnet_id      = "${aws_subnet.subnet_public3.id}"
  route_table_id = "${aws_route_table.route_table_public.id}"
}

resource "aws_route_table_association" "rt_association_private1" {
  subnet_id      = "${aws_subnet.subnet_private1.id}"
  route_table_id = "${aws_default_route_table.route_table_private.id}"
}

# Create security group for Load balancer
resource "aws_security_group" "load_balancer_sg" {
  name        = "load_balancer_sg"
  description = "load balancer security group"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "TLS from VPC"
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
    Name = "load_balance_sg"
  }
}

#Create Security group for bastion
resource "aws_security_group" "bastion_sg" {
    name = "bastion_sg"
    description = "used for bastion"
    vpc_id = "${aws_vpc.myvpc.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create security group for private ec2
resource "aws_security_group" "private_ec2" {
  name        = "private_sg_ec2"
  description = "private subnet for ec2"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "ingress"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private_ec2"
  }
}
#Create security group for private database
resource "aws_security_group" "private_db_sg" {
  name        = "private_db"
  description = "security group for private database"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "ingress"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    
    security_groups = ["${aws_security_group.private_ec2.id}", "${aws_security_group.load_balancer_sg.id}", "${aws_security_group.bastion_sg.id}"]
  }

  tags = {
    Name = "private_db_sg"
  }
}

#Create Application LB
resource "aws_lb" "Application_LB" {
  name               = "application-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.load_balancer_sg.id}"]
  subnets            = ["${aws_subnet.subnet_public1.id}",
  "${aws_subnet.subnet_public2.id}"]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}
#listener for load balancer
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = "${aws_lb.Application_LB.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.test.arn}"

  }
}

#Create aurora
resource "aws_rds_cluster" "default" {
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["us-east-2a", "us-east-2b"]
  database_name           = "${var.dbname}"
  master_username         = "${var.username_db}"
  master_password         = "${var.password_db}"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids =  ["${aws_security_group.private_db_sg.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
  skip_final_snapshot = true
  
}


#Making AMI

resource "random_id" "centos_ami" {
    byte_length = 3
}

resource "aws_ami_from_instance" "centos_ami_from_instance" { #making a new AMI based on an ec2
    name = "centos_ami-${random_id.centos_ami.b64}"
    source_instance_id = "${aws_instance.bastion.id}"

}

#Create key pair
resource "aws_key_pair" "key_pair" { #this will have the key pairs for the instances
    key_name = "${var.key_name}"
    public_key = "${file(var.public_key_path)}"
}

#Create bastion
resource "aws_instance" "bastion" {
    instance_type = "${var.instance_type}"
    ami = "${var.ami_bastion}"
    key_name  = "${aws_key_pair.key_pair.id}"
    subnet_id   = "${aws_subnet.subnet_public1.id}"
    vpc_security_group_ids   = ["${aws_security_group.bastion_sg.id}"]
}

#Create launch configuration
resource "aws_launch_configuration" "launch_configuration" {
  name_prefix   = "launch_configuration"
  image_id      = "${var.ami_bastion}"
  instance_type = "t2.micro"
  # spot_price    = "0.001" (if you want to use spot instance in your asg)

  lifecycle {
    create_before_destroy = true
  }
}

#Create autoscaling group
resource "aws_autoscaling_group" "asg_ec2" {
  name                 = "terraform-asg-example"
  launch_configuration = "${aws_launch_configuration.launch_configuration.name}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  health_check_grace_period = "${var.health_check_grace_period}" #Time (in seconds) after instance comes into service before checking health
  health_check_type = "${var.health_check_type}" #Controls how health checking is done
  desired_capacity = "${var.desired_capacity}" #The number of Amazon EC2 instances that should be running in the group
  #load_balancers = A list of elastic load balancer names to add to the autoscaling group names. Only valid for classic load balancers. For ALBs, use target_group_arns instead.
  target_group_arns = ["${aws_lb_target_group.test.arn}"]
  vpc_zone_identifier = ["${aws_subnet.subnet_private1.id}, ${aws_subnet.subnet_private2.id}"] #A list of subnet IDs to launch resources in

  lifecycle {
    create_before_destroy = true
  }
  tag {
        key = "name"
        value = "asg_ec2"
        propagate_at_launch = true
    }
}
#lb
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.myvpc.id}"
}
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.asg_ec2.id}"
  alb_target_group_arn   = "${aws_lb_target_group.test.arn}"
}

#Create route53
resource "aws_route53_zone" "primary" {
    name = "${var.domain_name}.com"
    delegation_set_id = "${var.delegation_set}"

}
# create www
resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "www.${var.domain_name}.com"
  type    = "A"
  
  alias {
        name = "${aws_lb.Application_LB.dns_name}"
        zone_id = "${aws_lb.Application_LB.zone_id}"
        evaluate_target_health = false
    }
}

