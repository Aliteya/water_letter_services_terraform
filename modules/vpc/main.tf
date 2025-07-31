locals {
  all_traffic = "0.0.0.0/0"
  db_azs      = 2
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = "Apologize VPC"
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main.id

  count      = length(var.public_subnet_cidrs)
  cidr_block = element(var.public_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Public subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main.id

  count      = length(var.private_subnet_cidrs)
  cidr_block = element(var.private_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private subnet ${count.index + 1}"
  }
}

# resource "aws_subnet" "isolated_private_subnet" {
#     vpc_id = aws_vpc.main.id
#     count = 1
#     cidr_block = var.isolated_subnet_cidr[count.index]

#     availability_zone = var.azs[local.db_azs]

#     tags = {
#         Name = "Isolated private subnet"
#     }
# }

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Apologize VPC IG"
  }
}

resource "aws_route_table" "second_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = local.all_traffic
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Apologize VPC second Route table"
  }
}

# resource "aws_route_table" "isolated_route" {
#     vpc_id = aws_vpc.main.id

#     tags = {
#         Name = "Apologize VPC isolated Route table"
#     }
# }

resource "aws_route_table_association" "public_subnet_asso" {
  route_table_id = aws_route_table.second_route.id
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

# resource "aws_route_table_association" "isolated_subnet_asso" {
#     route_table_id = aws_route_table.isolated_route.id
#     subnet_id = aws_subnet.isolated_private_subnet.id
# }