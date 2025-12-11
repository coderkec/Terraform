####################################
# 1. provider 설정
# 2. vpc 생성
# 3. IGW 생성 및 연결
# 4. Public Subnet 생성
# 5. Puslic Route Table 생성 및 연결
####################################

####################################
# 1. provider 설정
####################################
provider "aws" {
  region = "us-east-2"
}

####################################
# 2. vpc 생성
####################################
# * VPC 생성
# * DNS Hostnames 활성화
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

####################################
# 3. IGW 생성 및 연결
####################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

####################################
# 4. Public Subnet 생성
####################################
# Public Subnet 생성
# 공인 IP 자동 할당 활성화
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "myPubSN" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

####################################
# 5. Puslic Route Table 생성 및 연결
####################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# * default route
# * PubSN <- 연결 -> PubSN-RT
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "myPubRT-Association" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}
