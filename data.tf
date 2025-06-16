data "aws_vpc" "selected" {
  id = "${var.default_vpc_id}"
}

data "aws_subnet" "subnet1" {
  id = "${var.aws_subnet_1a_id}"
}

data "aws_subnet" "subnet2" {
  id = "${var.aws_subnet_1b_id}"
}
