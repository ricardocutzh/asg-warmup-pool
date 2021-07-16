data "aws_iam_policy" "ssm-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# defining instance profile for the ssh box
resource "aws_iam_policy" "policy_ssh" {
  name        = "${var.identifier}-${terraform.workspace}-ssh-policy-asg"
  path        = "/"
  description = "ssh box permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "es:*",
        "lambda:InvokeAsync",
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ssm:UpdateInstanceInformation",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetEncryptionConfiguration"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "kms:Decrypt"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
        ],
        "Resource": "${aws_s3_bucket.s3_bucket.arn}/*"
    },
    {
        "Action": [
            "secretsmanager:*",
            "ssm:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:CompleteLifecycleAction",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeTags",
            "ec2:DescribeInstances",
            "ec2:DescribeTags"
        ],
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "role_ssh" {
  name = "${var.identifier}-${terraform.workspace}-ssh-profile-asg"
  path = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "ssh-attach-permissions" {
  name       = "${var.identifier}-${terraform.workspace}-ssh-permissions-asg"
  roles      = [aws_iam_role.role_ssh.id]
  policy_arn = aws_iam_policy.policy_ssh.arn
}

resource "aws_iam_role_policy_attachment" "ssh-attach-permissions-ssm" {
  role       = aws_iam_role.role_ssh.id
  policy_arn = data.aws_iam_policy.ssm-policy.arn
}

resource "aws_iam_instance_profile" "ssh_profile" {
  name = "${var.identifier}-${terraform.workspace}-ssh-profile-asg"
  role = aws_iam_role.role_ssh.name
}