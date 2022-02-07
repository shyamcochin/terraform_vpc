### Create a New Custom VPC
#==========================
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  instance_tenancy     = var.vpc_instance_tenancy
  
  #tags = merge( var.project_tags, var.environment_tags, {Name = var.name}, )     
  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-VPC" }) 
  lifecycle {
    prevent_destroy = false
  }
}

### Provide TagName for Default SecurityGroup
#============================================
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-Default-SG" })
  lifecycle {
    prevent_destroy = false
  }
}

### Provide TagName for Default NetworkACL
#=========================================
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.custom_vpc.default_network_acl_id
  subnet_ids = [ "${aws_subnet.public_subnet.*.id}", "${aws_subnet.private_subnet.*.id}" ]
  #subnet_ids = [ "element(aws_subnet.public_subnet.*.id, count.index)","element(aws_subnet.private_subnet.*.id, count.index)" ]
  #subnet_ids = [ "${concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnet[*].id)}" ]
  
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-NACL" })
  lifecycle {
    prevent_destroy = false
    #ignore_changes = [subnet_ids]
  }
}

### Get the Availability Zones List
#==================================
data "aws_availability_zones" "available" {
  state = "available"
}

### Create Private Subnets for 2 Zones (DB and App Server)
#=========================================================
resource "aws_subnet" "private_subnet" {
  count             = var.number_of_private_subnets
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = element(var.private_subnet_cidr_blocks, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-PrivateSubnet-${count.index + 1}" })
  lifecycle {
    prevent_destroy = false
  }
}

### Create Public Subnets for 2 Zones (Bot and ELB)
#==================================================
resource "aws_subnet" "public_subnet" {
  count             = var.number_of_public_subnets
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-PublicSubnet-${count.index + 1}" })
  lifecycle {
    prevent_destroy = false
  }
}

### Create Internet Gateway for VPC
#==================================
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.custom_vpc,
  ]

  vpc_id = aws_vpc.custom_vpc.id

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-IGW" })
  lifecycle {
    prevent_destroy = false
  }
}

### Create PublicRoute Table (Default RT)
#========================================
resource "aws_default_route_table" "Public-Subnet-RT" {
  default_route_table_id = aws_vpc.custom_vpc.default_route_table_id
  depends_on = [
    aws_vpc.custom_vpc,
    aws_internet_gateway.Internet_Gateway
  ]

# Internet Gateway associate with PublicRoute Table
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-PublicRT" })
  lifecycle {
    prevent_destroy = false
  }
}

### Configuring PublicRoute Table Association with Public Subnet
#===============================================================
resource "aws_route_table_association" "PubSubnet-Association" {
  count = var.number_of_public_subnets
  depends_on = [
    aws_vpc.custom_vpc,
    aws_default_route_table.Public-Subnet-RT
  ]

# Public Subnet ID
  subnet_id = element(aws_subnet.public_subnet[*].id, count.index)

# Route Table ID
  route_table_id = aws_default_route_table.Public-Subnet-RT.id
    lifecycle {
    prevent_destroy = false
  }
}

### Create PrivateRoute Table (New RT)
#=====================================
resource "aws_route_table" "Private-Subnet-RT" {
  depends_on = [
    aws_vpc.custom_vpc
  ]

# Route table with VPC Association
  vpc_id = aws_vpc.custom_vpc.id

/*
# NAT Gateway associate with PrivateublicRoute Table
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }*/

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-PrivateRT" })
  lifecycle {
    prevent_destroy = false
  }
}

### Configuring PrivateRoute Table Association with Private Subnet
#=================================================================
resource "aws_route_table_association" "PriSubnet-Association" {
  count = var.number_of_private_subnets
  depends_on = [
    aws_vpc.custom_vpc,
    aws_route_table.Private-Subnet-RT
  ]

# Public Subnet ID
  subnet_id = element(aws_subnet.private_subnet[*].id, count.index)

# Route Table ID
  route_table_id = aws_route_table.Private-Subnet-RT.id
    lifecycle {
    prevent_destroy = false
  }
}


### NAT Configuration Section is Optional

### Create an Elastic IP for the NAT Gateway!
#============================================
resource "aws_eip" "nat-gateway-eip" {
  count = var.enable_nat_gateway == true ? 1 : 0    
  depends_on = [
    aws_internet_gateway.Internet_Gateway
  ]

  vpc  = true

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-EIP-${count.index + 1}" })
  lifecycle {
    prevent_destroy = false
  }
}

### Create the NAT Gateway!
#==========================
resource "aws_nat_gateway" "nat_gateway" {
  count = var.enable_nat_gateway == true ? 1 : 0     
  depends_on = [
    aws_eip.nat-gateway-eip
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = element(aws_eip.nat-gateway-eip.*.id, count.index)
  
  # Associating it in the Public Subnet!(Mentioning where the NAT should be launched)
  subnet_id = element(aws_subnet.public_subnet.*.id, count.index)

  tags = merge(var.project_tags, var.environment_tags, { Name = "${lookup(var.project_tags, "PlatformName")}-${lookup(var.project_tags, "Product")}-NAT-${count.index + 1}" })
  lifecycle {
    prevent_destroy = false
  }
}

### Configure Private RouteTable for adding NAT Gateway
#======================================================
resource "aws_route" "nat_to_private_RT" {
  count = var.enable_nat_gateway == true ? 1 : 0
  route_table_id              = aws_route_table.Private-Subnet-RT.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  depends_on = [
    aws_nat_gateway.nat_gateway
  ]
}
