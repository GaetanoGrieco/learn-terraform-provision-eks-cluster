data "aws_iam_policy_document" "cw_ng_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "cw_nodegroup" {
  name        = "EKSNodegroupCloudWatchPolicy-${module.eks.cluster_name}"
  description = "Allow nodegroups to write logs to CloudWatch"
  policy      = data.aws_iam_policy_document.cw_ng_policy.json
}

resource "aws_iam_role_policy_attachment" "ng_one_cloudwatch" {
  role       = module.eks.eks_managed_node_groups["one"].iam_role_name
  policy_arn = aws_iam_policy.cw_nodegroup.arn
}

resource "aws_iam_role_policy_attachment" "ng_two_cloudwatch" {
  role       = module.eks.eks_managed_node_groups["two"].iam_role_name
  policy_arn = aws_iam_policy.cw_nodegroup.arn
}