resource "aws_iam_policy" "github_oidc_policy" {
  name        = "${local.product}-github"
  description = "Policy for GitHub Actions to access AWS resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "github_oidc_role" {
  name = "${local.product}-github"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in local.repos : "repo:${local.github_org}/${repo}:*"
            ]
          }
        }
      }
    ]
  })
  tags = {
    Name = "${local.product}-github"
  }
}

resource "aws_iam_role_policy_attachment" "github_oidc_policy_attachment" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.github_oidc_policy.arn
}