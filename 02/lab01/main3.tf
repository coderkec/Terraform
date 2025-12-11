#######################################
# 1. NAT Gateway -> Pubclic Subnet
# 2. Private Subnet(myVPC) 생성
# 3. Private Route Table 생성 및 연결
# 4. SG 생성
# 5. EC2 생성
#######################################

#######################################
# 1. NAT Gateway -> Pubclic Subnet
#######################################
# * NAT Gateway를 PubSN에 생성
# * EIP 생성된 상태에서 작업

resource "aws_eip" "myEIP" {
  domain = "vpc"

  tags = {
    Name = "myEIP"
  }
}

resource "aws_nat_gateway" "myNAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSN.id

  tags = {
    Name = "myNAT-GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.myIGW]
}

#######################################
# 2. Private Subnet(myVPC) 생성
#######################################
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "myPriSN"
  }
}

#######################################
# 3. Private Route Table 생성 및 연결
#######################################
# * NAT GW를 default route로 설정
# * PriSN <-> PriSN-RT 연결
resource "aws_route_table" "myPriRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.myNAT-GW.id
  }

  tags = {
    Name = "myPriRT"
  }
}
resource "aws_route_table_association" "mypriRT-Association" {
  subnet_id      = aws_subnet.myPriSN.id
  route_table_id = aws_route_table.myPriRT.id
}

#######################################
# 4. SG 생성
#######################################
# * mySG 생성
# * myEC2가 사용할 SG
# * 22/tcp, 80/tcp, 443/tcp 허용
resource "aws_security_group" "mySG2" {
  name        = "mySG2"
  description = "Allow TLS inbound 22/tcp, 80/tcp, 443/tcp traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG2"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_22" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = aws_vpc.myVPC.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_80" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = aws_vpc.myVPC.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_443" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "mySG2_all" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#######################################
# 5. EC2 생성
#######################################
# * mySG2 포함
# * user_data(WEB Server, SSH Server)
# * user_data가 변경 되었을때 재생성하도록 설정

resource "aws_instance" "myEC2-2" {
  ami                    = "ami-00e428798e77d38d9"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mySG2.id]
  subnet_id              = aws_subnet.myPriSN.id

  user_data_replace_on_change = true
  user_data                   = <<-EOF
        #!/bin/bash
        dnf install -y httpd mod_ssl
        echo "My Web Server Test Page" > /var/www/html/index.html  
        systemctl enable --now httpd
        EOF

  tags = {
    Name = "myEC2-2"
  }
}