variable "region" {
  type    = string
  default = "us-east-2"
}

variable "ami" {
  type    = string
  default = "ami-07c8bc5c1ce9598c3"
}

variable "ssh_pub_key" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.128.0.0/24"
}

variable "public_subnet" {
  type    = string
  default = "10.128.0.0/25"
}

variable "private_subnet" {
  type    = string
  default = "10.128.0.128/25"
}

variable "instance_count" {
  type = number
  default = 3
}
