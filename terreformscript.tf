provider "aws" {
  region     = "us-east-1"
}

resource "aws_vpc" "demovpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "tfvpc"
  }
}
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.demovpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "demovpc-privatesubent"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.demovpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "demovpc-publicsubnet"
  }
}

resource "aws_internet_gateway" "demo-GW" {
  vpc_id = aws_vpc.demovpc.id

  tags = {
    Name = "tf-GW"
  }
}

resource "aws_route_table" "demovpc-publicrt" {
  vpc_id = aws_vpc.demovpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-GW.id
  }
  tags = {
    Name = "demovpc-routetable"
  }
}

resource "aws_route_table_association" "association1" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.demovpc-publicrt.id
}

resource "aws_route_table_association" "association2" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.demovpc-publicrt.id
}


resource "aws_security_group"  "demovpcsg"  {
  name        =  "demovpcvsg"
  description =  "Allow TLS inbound traffic 22"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demovpcsg"
  }
}

resource "aws_instance" "tf_instance" {
  ami           = "ami-000db10762d0c4c05"
  count=1
  instance_type = "t2.micro"
  key_name   = "myEC2kp"
  subnet_id      = "${aws_subnet.public.id}"
  security_groups = [aws_security_group.demovpcsg.id]
  tags = {
    Name = "tf_instance"
  }
}
