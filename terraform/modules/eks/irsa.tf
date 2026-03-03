#------------------------------------------------------------------------------
# IRSA - IAM Roles for Service Accounts
# Allows Kubernetes pods to assume specific IAM roles
#------------------------------------------------------------------------------

# Helper local for OIDC provider ID
locals {
  oidc_provider_id = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

#------------------------------------------------------------------------------
# EXTERNAL DNS
# Allows ExternalDNS to manage Route53 records
#------------------------------------------------------------------------------

# Policy document - what ExternalDNS can do
data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "ChangeResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid    = "ListHostedZonesAndRecords"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

# Create the policy
resource "aws_iam_policy" "external_dns" {
  name        = "${var.cluster_name}-external-dns"
  description = "IAM policy for ExternalDNS to manage Route53 records"
  policy      = data.aws_iam_policy_document.external_dns.json

  tags = {
    Name        = "${var.cluster_name}-external-dns"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Trust policy - who can assume this role (ExternalDNS service account)
data "aws_iam_policy_document" "external_dns_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# The IRSA role
resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json

  tags = {
    Name        = "${var.cluster_name}-external-dns"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}

#------------------------------------------------------------------------------
# AWS LOAD BALANCER CONTROLLER
# Allows AWS LB Controller to create ALBs/NLBs
#------------------------------------------------------------------------------

# Policy document - what AWS LB Controller can do
data "aws_iam_policy_document" "aws_lb_controller" {
  statement {
    sid    = "IAMCreateServiceLinkedRole"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid    = "EC2Permissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ELBPermissions"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CognitoPermissions"
    effect = "Allow"
    actions = [
      "cognito-idp:DescribeUserPoolClient"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ACMPermissions"
    effect = "Allow"
    actions = [
      "acm:ListCertificates",
      "acm:DescribeCertificate"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "WAFPermissions"
    effect = "Allow"
    actions = [
      "waf-regional:*",
      "wafv2:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ShieldPermissions"
    effect = "Allow"
    actions = [
      "shield:*"
    ]
    resources = ["*"]
  }
}

# Create the policy
resource "aws_iam_policy" "aws_lb_controller" {
  name        = "${var.cluster_name}-aws-lb-controller"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.aws_lb_controller.json

  tags = {
    Name        = "${var.cluster_name}-aws-lb-controller"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Trust policy - who can assume this role
data "aws_iam_policy_document" "aws_lb_controller_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# The IRSA role
resource "aws_iam_role" "aws_lb_controller" {
  name               = "${var.cluster_name}-aws-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role.json

  tags = {
    Name        = "${var.cluster_name}-aws-lb-controller"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  policy_arn = aws_iam_policy.aws_lb_controller.arn
  role       = aws_iam_role.aws_lb_controller.name
}