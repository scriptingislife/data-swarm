provider "aws" {
    region = "us-east-1"
}

resource "aws_sns_topic" "2fa_swarm" {
    name = "2fa-swarm"
}

resource "aws_iam_role" "2fa_lambda_role" {
    name = "2fa_lambda_role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

data "aws_iam_policy" "SNSFullAccess" {
    arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_policy" "SNSPublish" {
    policy = <<EOF
{
    "Version": "2012-10-17"
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sns:publish",
            "Resource": "${aws_sns_topic.2fa_swarm.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "2fa_sns_attach" {
    name = "2fa_sns_attach"
    roles = ["${aws_iam_role.2fa_lambda_role.name}"]
    policy_arn = "${}"
}

resource "aws_lambda_function" "swarm_manager" {
    filename = "manager/build/build.zip"
    source_code_hash = "${filebase64sha256("manager/build/build.zip")}"
    function_name = "2fa_swarm_manager"
    role = "${aws_iam_role.2fa_lambda_role.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "5"
}

resource "aws_lambda_function" "swarm_worker" {
    filename = "worker/build/build.zip"
    source_code_hash = "${filebase64sha256("worker/build/build.zip")}"
    function_name = "2fa_swarm_worker"
    role = "${aws_iam_role.2fa_lambda_role.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "5"
}

resource "aws_sns_topic_subscription" "2fa_swarm_target" {
    topic_arn = "${aws_sns_topic.2fa_swarm.arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.swarm_worker.arn}"
}
