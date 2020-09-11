provider "aws" {
  region = var.region
}


resource "aws_instance" "instance" {
  ami                    = var.ami
  instance_type          = "t2.micro"
}
