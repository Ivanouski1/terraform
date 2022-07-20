
variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "common_tags" {
  type = map(any)
  default = {
    Terraform : "true",
    Project : "website",
    Owner : "Andrei Ivanouski1"
  }
}

variable "instance_type" {
  description = "type web instance"
  default     = "t3.micro"
}


variable "letters" {
  type    = list(any)
  default = ["a", "b", "c"]
}

variable "public_subnet_cidr" {
  default = "10.10."
 
}

variable "private_subnet_cidr" {
  default = "10.10."
  
}