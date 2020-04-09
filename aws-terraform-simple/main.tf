provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}" #access key for user "terraform"
  secret_key = "${var.secret_key}"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "tf_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true

  
  
}

resource "aws_internet_gateway" "tf_internet_gateway" {
  vpc_id = "${aws_vpc.tf_vpc.id}"

  tags = {
    Name = "tf_igw"
  }
}
resource "aws_route_table" "tf_rt_public" {
  vpc_id = "${aws_vpc.tf_vpc.id}"

  route {
    cidr_block = "${var.route_table_public}"
    gateway_id = "${aws_internet_gateway.tf_internet_gateway.id}"

  }
 
}

/*resource "aws_subnet" "tf_subnet_public" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  count = 3
  cidr_block = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
*/
resource "aws_subnet" "tf_subnet_public1"{
  vpc_id = "${aws_vpc.tf_vpc.id}"
  cidr_block = "${var.public_cidr_1}"
  map_public_ip_on_launch = true
  availability_zone = "${var.availability_zone1}"

}
resource "aws_subnet" "tf_subnet_public2"{
  vpc_id = "${aws_vpc.tf_vpc.id}"
  cidr_block = "${var.public_cidr_2}"
  map_public_ip_on_launch = true
  availability_zone = "${var.availability_zone2}"

}
resource "aws_subnet" "tf_subnet_public3"{
  vpc_id = "${aws_vpc.tf_vpc.id}"
  cidr_block = "${var.public_cidr_3}"
  map_public_ip_on_launch = true
  availability_zone = "${var.availability_zone3}"

}

resource "aws_route_table_association" "tf_public_assoc1" {
  subnet_id      = "${aws_subnet.tf_subnet_public1.id}"
  route_table_id = "${aws_route_table.tf_rt_public.id}"
}
resource "aws_route_table_association" "tf_public_assoc2" {
  subnet_id      = "${aws_subnet.tf_subnet_public2.id}"
  route_table_id = "${aws_route_table.tf_rt_public.id}"
}
resource "aws_route_table_association" "tf_public_assoc3" {
  subnet_id      = "${aws_subnet.tf_subnet_public3.id}"
  route_table_id = "${aws_route_table.tf_rt_public.id}"
}
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.tf_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
/*resource "aws_subnet" "tf_subnet_private" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  count = 3
  cidr_block = "${var.private_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

}
*/
resource "aws_subnet" "tf_subnet_private1" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  cidr_block = "${var.private_cidr1}"
  availability_zone = "${var.availability_zone1}"

}
resource "aws_subnet" "tf_subnet_private2" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  cidr_block = "${var.private_cidr2}"
  availability_zone = "${var.availability_zone2}"

}
resource "aws_subnet" "tf_subnet_private3" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  cidr_block = "${var.private_cidr3}"
  availability_zone = "${var.availability_zone3}"

}
resource "aws_eip" "lb" {
  vpc      = true
}
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.lb.id}"
  subnet_id     = "${aws_subnet.tf_subnet_public1.id}"

}


resource "aws_default_route_table" "route_table_private" {
  default_route_table_id = "${aws_vpc.tf_vpc.default_route_table_id}"

  route {
    cidr_block = "${var.route_table_private}"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"

  }

}

resource "aws_route_table_association" "tf_private_assoc1" {
  subnet_id      = "${aws_subnet.tf_subnet_private1.id}"
  route_table_id = "${aws_default_route_table.route_table_private.id}"
}
resource "aws_route_table_association" "tf_private_assoc2" {
  subnet_id      = "${aws_subnet.tf_subnet_private2.id}"
  route_table_id = "${aws_default_route_table.route_table_private.id}"
}
resource "aws_route_table_association" "tf_private_assoc3" {
  subnet_id      = "${aws_subnet.tf_subnet_private3.id}"
  route_table_id = "${aws_default_route_table.route_table_private.id}"
}
resource "aws_key_pair" "tf_auth" {
    key_name = "${var.key_name}"
    public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "tf_bastion" {
    instance_type = "${var.instance_type}"
    ami = "${var.ami_bastion}"
    key_name  = "${aws_key_pair.tf_auth.id}"
    subnet_id   = "${aws_subnet.tf_subnet_public1.id}"
    vpc_security_group_ids   = ["${aws_security_group.allow_ssh.id}"]

}
resource "aws_instance" "web" {
    instance_type = "${var.instance_type}"
    ami = "${var.ami_bastion}"
    key_name  = "${aws_key_pair.tf_auth.id}"
    subnet_id   = "${aws_subnet.tf_subnet_public2.id}"
    vpc_security_group_ids   = ["${aws_security_group.allow_http.id}", "${aws_security_group.allow_ssh.id}"]
    user_data = "${file("web.sh")}"

}
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "http"
  vpc_id      = "${aws_vpc.tf_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}
resource "aws_instance" "mysql" {
    instance_type = "${var.instance_type}"
    ami = "${var.ami_bastion}"
    key_name  = "${aws_key_pair.tf_auth.id}"
    subnet_id   = "${aws_subnet.tf_subnet_private1.id}"
    vpc_security_group_ids   = ["${aws_security_group.allow_sql.id}", "${aws_security_group.allow_ssh.id}"]
    user_data = "${file("mysql.sh")}"
    
    
}
resource "aws_security_group" "allow_sql" {
  name        = "allow_sql"
  description = "http"
  vpc_id      = "${aws_vpc.tf_vpc.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_sql"
  }
}


