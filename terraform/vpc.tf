data "aws_availability_zones" "available" { state = "available" }
resource "aws_vpc" "main" {
cidr_block = "192.168.0.0/16"
enable_dns_hostnames = true
enable_dns_support = true
tags = { Name = "${var.app_name}-vpc" }
}
resource "aws_internet_gateway" "main" {
vpc_id = aws_vpc.main.id
tags = { Name = "${var.app_name}-igw" }
}
# Public subnets — ALB lives here (spans 2 AZs for high availability)
resource "aws_subnet" "public" {
count = 2
vpc_id = aws_vpc.main.id
cidr_block = "192.168.${count.index}.0/24"
availability_zone = data.aws_availability_zones.available.names[count.index]
map_public_ip_on_launch = true
tags = { Name = "${var.app_name}-public-${count.index + 1}" }
}
# Private subnets — ECS tasks run here (no direct internet access)
resource "aws_subnet" "private" {
count = 2
vpc_id = aws_vpc.main.id
cidr_block = "192.168.${count.index + 10}.0/24"
availability_zone = data.aws_availability_zones.available.names[count.index]
tags = { Name = "${var.app_name}-private-${count.index + 1}" }
}
# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
domain = "vpc"
tags = { Name = "${var.app_name}-nat-eip" }
}
# NAT Gateway — allows ECS in private subnets to pull images from ECR
resource "aws_nat_gateway" "main" {
allocation_id = aws_eip.nat.id
subnet_id = aws_subnet.public[0].id
depends_on = [aws_internet_gateway.main]
tags = { Name = "${var.app_name}-nat-gw" }
}


# Route tables and associations
resource "aws_route_table" "public" {
vpc_id = aws_vpc.main.id
route { cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.main.id }
tags = { Name = "${var.app_name}-public-rt" }
}
resource "aws_route_table" "private" {
vpc_id = aws_vpc.main.id
route { cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.main.id }
tags = { Name = "${var.app_name}-private-rt" }
}
resource "aws_route_table_association" "public" {
count = 2
subnet_id = aws_subnet.public[count.index].id
route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
count = 2
subnet_id = aws_subnet.private[count.index].id
route_table_id = aws_route_table.private.id
}
