data "aws_iam_policy_document" "policyDocEKS" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}



data "aws_iam_policy_document" "policyDocNodeEKS" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "policySnsSubDaily" {
  name        = "policySnsSubDaily"
  path        = "/"
  description = "policySnsSubDaily"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "policySqsSubDaily" {
  name        = "policySqsSubDaily"
  path        = "/"
  description = "policySqsSubDaily"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "roleEKSDaily" {
  name               = "roleEKSDaily"
  assume_role_policy = data.aws_iam_policy_document.policyDocEKS.json

  inline_policy {
    name = "EKSEC2Policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
        ],
        Resource = "*",
      }],
    })
  }
}

resource "aws_iam_role" "roleNodeEKSDaily" {
  name               = "roleNodeEKSDaily"
  assume_role_policy = data.aws_iam_policy_document.policyDocNodeEKS.json
}

resource "aws_iam_role" "roleNodeSecretsDaily" {
  name = "roleNodeSecretsDaily"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            replace("${aws_eks_cluster.clusterdailybanking-case.identity.0.oidc.0.issuer}:sub", "https://", "") = "system:serviceaccount:default:irsasecrets"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.roleEKSDaily.name
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.roleEKSDaily.name
}

resource "aws_iam_role_policy_attachment" "policyroleNodeEKSDaily" {
  role       = aws_iam_role.roleNodeEKSDaily.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cniPolicyroleNodeEKSDaily" {
  role       = aws_iam_role.roleNodeEKSDaily.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecrPolicyroleNodeEKSDaily" {
  role       = aws_iam_role.roleNodeEKSDaily.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "elbPolicyroleNodeEKSDaily" {
  role       = aws_iam_role.roleNodeEKSDaily.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "sns_sub_policy_attachment" {
  role       = aws_iam_role.roleNodeSecretsDaily.name
  policy_arn = aws_iam_policy.policySnsSubDaily.arn
}

resource "aws_iam_role_policy_attachment" "sqs_sub_policy_attachment" {
  role       = aws_iam_role.roleNodeSecretsDaily.name
  policy_arn = aws_iam_policy.policySqsSubDaily.arn
}

resource "aws_iam_role_policy_attachment" "ec2PolicyroleNodeEKSDaily" {
  role       = aws_iam_role.roleNodeEKSDaily.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_eks_cluster" "clusterdailybanking-case" {
  name     = "dailybanking-case"
  role_arn = aws_iam_role.roleEKSDaily.arn

  vpc_config {
    subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.policyEKSAmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.policyEKSAmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "appNodeGroupdailybanking-case" {
  cluster_name    = aws_eks_cluster.clusterdailybanking-case.name
  node_group_name = "appNodedailybanking-case"
  node_role_arn   = aws_iam_role.roleNodeEKSDaily.arn
  subnet_ids      = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]

  launch_template {
    id      = aws_launch_template.eks_node_template.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 3
    max_size     = 7
    min_size     = 1
  }

  capacity_type = "SPOT"

  tags = {
    "Name"                           = "eks-daily-node-app"
    "eks.amazonaws.com/capacityType" = "SPOT"
  }

  depends_on = [
    aws_iam_role_policy_attachment.policyroleNodeEKSDaily,
    aws_iam_role_policy_attachment.cniPolicyroleNodeEKSDaily,
    aws_iam_role_policy_attachment.ec2PolicyroleNodeEKSDaily,
  ]
}


data "tls_certificate" "thumbprint_eks" {
  url = aws_eks_cluster.clusterdailybanking-case.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "oidc_eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.thumbprint_eks.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.clusterdailybanking-case.identity.0.oidc.0.issuer
}

resource "aws_launch_template" "eks_node_template" {
  name_prefix   = "eks-node-template-"
  instance_type = "t3.large"

  metadata_options {
    http_tokens   = "optional"
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
