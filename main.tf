
terraform {
    required_providers{
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}


provider "aws" {
    region = "us-east-1"
}




resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "main-vpc"
    }
}




resource "aws_subnet" "public" {

    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    map_public_ip_on_launch = true

    tags = {
        Name = "public-subnet-1"
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"


    tags = {
        Name = "private-subnet-1"
    }
}





resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main-igw"

    }
}




resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id


    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }


    tags = {
        Name = "public-route-table"
    }
}


resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}



resource "aws_security_group" "web" {
    name = "web-sg"
    description = "Allow TLS/HTTP inbound traffic"
    vpc_id = aws_vpc.main.id

    ingress{
        description = "HTTPS from anywhere"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    ingress {
        description = "HTTP from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks =["0.0.0.0/0"]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks =["0.0.0.0/0"]
    }

    tags = {
        Name = "web-sg"

    }
}


resource "aws_security_group" "db" {
    name = "db-sg"
    description = "Allow traffic from the web security group"
    vpc_id = aws_vpc.main.id 


    ingress {
        description = "MySQL from web-sg"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.web.id]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }


    tags = {
        Name = "db-sg"
    }
}






resource "aws_instance" "web" {
    ami = "ami-02b3c03c6fadb6e2c"
    instance_type = "t2.micro"

    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.web.id]

    tags = {
        Name = "web-server"
    }
}


resource "aws_instance" "db" {
    ami = "ami-02b3c03c6fadb6e2c"
    instance_type = "t2.micro"


    subnet_id = aws_subnet.private.id
    vpc_security_group_ids = [aws_security_group.db.id]

    tags = {
        Name = "db-server"
    }
}



