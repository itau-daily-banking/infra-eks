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

resource "aws_iam_policy" "policySnsSub-2" {
  name        = "policySnsSub-2"
  path        = "/"
  description = "policySnsSub-2"

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

resource "aws_iam_policy" "policy_sqs_cancelamento" {
  name        = "policy-sqs-cancelamento"
  description = "Permite acesso ao SQS de cancelamento"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "arn:aws:sqs:us-east-1:011706314791:cancelamento-queue"
      }
    ]
  })
}



resource "aws_iam_role" "roleEKS-2" {
  name               = "roleEKS-2"
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

resource "aws_iam_role" "roleNodeEKS-2" {
  name               = "roleNodeEKS-2"
  assume_role_policy = data.aws_iam_policy_document.policyDocNodeEKS.json
}

resource "aws_iam_role" "roleNodeSecrets-2" {
  name = "roleNodeSecrets-2"

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

resource "aws_iam_role_policy_attachment" "attach_policy_sqs_cancelamento" {
  role       = aws_iam_role.roleNodeSecrets-2.name
  policy_arn = aws_iam_policy.policy_sqs_cancelamento.arn
}


resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.roleEKS-2.name
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.roleEKS-2.name
}

resource "aws_iam_role_policy_attachment" "policyroleNodeEKS-2" {
  role       = aws_iam_role.roleNodeEKS-2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cniPolicyroleNodeEKS-2" {
  role       = aws_iam_role.roleNodeEKS-2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecrPolicyroleNodeEKS-2" {
  role       = aws_iam_role.roleNodeEKS-2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "elbPolicyroleNodeEKS-2" {
  role       = aws_iam_role.roleNodeEKS-2.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "sns_sub_policy_attachment" {
  role       = aws_iam_role.roleNodeSecrets-2.name
  policy_arn = aws_iam_policy.policySnsSub-2.arn
}

resource "aws_iam_role_policy_attachment" "ec2PolicyroleNodeEKS-2" {
  role       = aws_iam_role.roleNodeEKS-2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_eks_cluster" "clusterdailybanking-case" {
  name     = "dailybanking-case"
  role_arn = aws_iam_role.roleEKS-2.arn

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
  node_role_arn   = aws_iam_role.roleNodeEKS-2.arn
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
    "Name"                           = "eks-node-app"
    "eks.amazonaws.com/capacityType" = "SPOT"
  }

  depends_on = [
    aws_iam_role_policy_attachment.policyroleNodeEKS-2,
    aws_iam_role_policy_attachment.cniPolicyroleNodeEKS-2,
    aws_iam_role_policy_attachment.ec2PolicyroleNodeEKS-2,
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
