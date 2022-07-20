#---------Provisioner Highly Available web -------------
provider "aws" {

  shared_credentials_files = ["cred_files/aws_credentials"]
  shared_config_files      = ["cred_files/aws_config"]

}

#-----create key-pair from pre-created keys-------
resource "aws_key_pair" "aws_key" {

  key_name   = "aws-key"
  public_key = data.local_file.public_key.content
 #public_key = file("cred_files/aws_key.pub")
}


#-------Dynamic SG--------------
resource "aws_security_group" "my_firewall" {
  name   = "my-firewall"
  vpc_id = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = ["80", "443", "22"] # Ingress rules HTTP, HTTPS, SSH
    content {
      description = "HTTP, HTTPS, SSH"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "my-firewall"
    }
  )
}

#-----Launch-configuration---------
resource "aws_launch_configuration" "web_tamplate" {
  name                        = "web-tamplate"
  image_id                    = data.aws_ami.latest_ami.id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.my_firewall.id]
  user_data                   = data.local_file.script_apache.content
 #user_data                   = file("script_files/apache.sh")
  key_name                    = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}


#-------ASG-------------
resource "aws_autoscaling_group" "a_s_g" {
  name                 = "a-s-g"
  launch_configuration = aws_launch_configuration.web_tamplate.name
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = aws_subnet.public.*.id
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.web_elb.name]

  #depends_on = [aws_alb_listener.listener_http]
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }


}

#------VPC------------
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"

  tags = merge(
    var.common_tags,
    {
      Name = "my-vpc"
    }
  )
}


resource "aws_subnet" "public" {
  count                   = "3"
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "${var.public_subnet_cidr}${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.az_in_region.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "public_${var.letters[count.index]}"
    }
  )
}

resource "aws_subnet" "private" {
  count             = "3"
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "${var.private_subnet_cidr}${10 + count.index}.0/24"
  availability_zone = data.aws_availability_zones.az_in_region.names[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "private_${var.letters[count.index]}"
    }
  )
}

resource "aws_internet_gateway" "cloud_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "cloud-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

#-------ELB-------------
resource "aws_elb" "web_elb" {
  name            = "web-elb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.my_firewall.id]


  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    target              = "HTTP:80/"
    interval            = 10
    timeout             = 5
  }

  tags = {
    Name = "web-elb"
  }

}
output "ELB" {
  value = aws_elb.web_elb.dns_name
}