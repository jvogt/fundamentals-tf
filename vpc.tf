resource "aws_vpc" "fundamentals_wkshp-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_vpc"
    )
  )}"

}

resource "aws_internet_gateway" "fundamentals_wkshp-gateway" {
  vpc_id = "${aws_vpc.fundamentals_wkshp-vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_gateway"
    )
  )}"

}

resource "aws_route" "fundamentals_wkshp-internet-access" {
  route_table_id         = "${aws_vpc.fundamentals_wkshp-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.fundamentals_wkshp-gateway.id}"
}

resource "aws_subnet" "fundamentals_wkshp-subnet-a" {
  vpc_id                  = "${aws_vpc.fundamentals_wkshp-vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_subnet_a"
    )
  )}"

}

resource "aws_subnet" "fundamentals_wkshp-subnet-b" {
  vpc_id                  = "${aws_vpc.fundamentals_wkshp-vpc.id}"
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}b"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_subnet_b"
    )
  )}"

}

output "vpc_id" {
  value = "${aws_vpc.fundamentals_wkshp-vpc.id}"
}

output "subnet_id" {
  value = "${aws_subnet.fundamentals_wkshp-subnet-a.id}"
}
