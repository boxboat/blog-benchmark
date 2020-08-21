variable "location" {
  type    = string
  default = "East US"
}

variable "network_cidr" {
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

variable "ssh_pub_key" {
  type = string
}
