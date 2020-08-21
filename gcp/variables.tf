variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "zone" {
  type = string
  default = "us-east1-b"
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
  type    = number
  default = 3
}

variable "compute_image" {
  type    = string
  default = "ubuntu-1804-bionic-v20200807"
}
