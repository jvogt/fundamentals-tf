resource "aws_iam_role" "training_wkst_role" {
  name = "training_wkst_role"
  path = "/"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "training_wkst_role"
    )
  )}"

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

resource "aws_iam_role_policy" "training_wkst_policy" {
  name = "training_wkst_policy"
  role = "${aws_iam_role.training_wkst_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::123456789:role/RoleName"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "training_wkst_profile" {
  name = "training_wkst_profile"
  role = "${aws_iam_role.training_wkst_role.name}"
}