variable "project" {
  type = string
}

variable "zone" {
  type = string
  default = "us-east1-b"
}

variable "compute_image" {
  type    = string
  default = "ubuntu-1804-bionic-v20200807"
}
