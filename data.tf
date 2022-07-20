

data "local_file" "public_key" {
  filename = "./cred_files/aws_key.pub"
}

data "local_file" "script_apache" {
  filename = "./script_files/apache.sh"
}

#-------extract next data-----
data "aws_availability_zones" "az_in_region" {}
data "aws_ami" "latest_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
