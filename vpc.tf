resource "aws_default_vpc" "vpcdailybanking-case" {
  tags = {
    Name = "Default VPC to Tech Challenge"
  }
}

resource "aws_default_subnet" "subnetdailybanking-case" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "Default subnet for us-east-1a to Tech Challenge",
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/dailybanking-case" = "owned"
  }
}

resource "aws_default_subnet" "subnetdailybanking-case2" {
  availability_zone = "us-east-1b"

  tags = {
    Name = "Default subnet for us-east-1b to Tech Challenge",
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/dailybanking-case" = "owned"
  }
}