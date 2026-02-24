resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}

resource "aws_subnet" "Public" {
  vpc_id                  = aws_vpc.main.id
  for_each                = zipmap(var.public_subnet_cidrs, var.azs)
  cidr_block              = each.key
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                                        = "public-subnet-${each.value}"
      "kubernetes.io/role/elb"                    = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "main-igw" })
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "public-rt" })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each       = aws_subnet.Public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "Private" {
  vpc_id            = aws_vpc.main.id
  for_each          = zipmap(var.private_subnet_cidrs, var.azs)
  cidr_block        = each.key
  availability_zone = each.value

  tags = merge(
    var.tags,
    {
      Name                                        = "private-subnet-${each.value}"
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "private-rt" })
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each       = aws_subnet.Private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.Public)[0].id

}

resource "aws_route" "private_internet_access" {
  count                  = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id         = aws_nat_gateway.ngw[0].id
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
}