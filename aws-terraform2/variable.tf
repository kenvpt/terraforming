variable "region" {}
variable "access_key" {}
variable "secret_key" {}
variable "cidr_block" {}
variable "cidrs"{
    type = "map"
}
variable "az1" {}
variable "az2" {}
variable "az3" {}
variable "instance_class" {}
variable "dbname" {}
variable "username_db" {}
variable "password_db" {}
variable "domain_name" {}
variable "min_size" {}
variable "max_size" {}
variable "health_check_grace_period" {}
variable "health_check_type" {}
variable "desired_capacity" {}
variable "delegation_set" {}
variable "instance_type" {}
variable "ami_bastion" {}
variable "key_name" {}
variable "public_key_path" {}
variable "wordpress_commands" {}
variable "local_ip" {}
