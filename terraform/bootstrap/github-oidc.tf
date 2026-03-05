#------------------------------------------------------------------------------
# GITHUB OIDC PROVIDER
# Allows GitHub Actions to authenticate with AWS without long-lived credentials
# Reference: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
#------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name    = "GitHub Actions OIDC"
    Project = var.project_name
  }
}

#------------------------------------------------------------------------------
# TRUST POLICY
# Defines WHO can assume the role (only your specific repo)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Security: Only tokens with this audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Security: Only YOUR repo can assume this role
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:environment:*"
      ]
    }
  }
}

#------------------------------------------------------------------------------
# IAM ROLE
# The role GitHub Actions will assume
#------------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name    = "${var.project_name}-github-actions"
    Project = var.project_name
  }
}

#------------------------------------------------------------------------------
# PERMISSIONS POLICY
# Defines WHAT the role can do (Terraform needs broad AWS access)
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_permissions" {
  # EKS Management
  statement {
    sid    = "EKSFullAccess"
    effect = "Allow"
    actions = [
      "eks:*"
    ]
    resources = ["*"]
  }

  # VPC and Networking
  statement {
    sid    = "VPCFullAccess"
    effect = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = ["*"]
  }

  # IAM (needed to create roles for EKS)
  statement {
    sid    = "IAMFullAccess"
    effect = "Allow"
    actions = [
      "iam:*"
    ]
    resources = ["*"]
  }

  # S3 (for Terraform state)
  statement {
    sid    = "S3StateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/*"
    ]
  }

  # DynamoDB (for state locking)
  statement {
    sid    = "DynamoDBLockAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.lock_table_name}"]
  }

  # Route53 (for DNS)
  statement {
    sid    = "Route53Access"
    effect = "Allow"
    actions = [
      "route53:*"
    ]
    resources = ["*"]
  }

  # KMS (EKS secrets encryption)
  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.project_name}-github-actions-policy"
  description = "Permissions for GitHub Actions to run Terraform"
  policy      = data.aws_iam_policy_document.github_actions_permissions.json

  tags = {
    Name    = "${var.project_name}-github-actions-policy"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}