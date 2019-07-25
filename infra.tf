provider "aws" {
    region = "us-east-1"
}

resource "aws_sns_topic" "2fa_swarm" {
    name = "2fa-swarm"
}

resource "aws_iam_role" "2fa_lambda_manager" {
    name = "2fa_lambda_manager"
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

resource "aws_iam_role" "2fa_lambda_worker" {
    name = "2fa_lambda_worker"
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

resource "aws_iam_policy" "SNSPublish" {
    policy = <<EOF
{
    "Version": "2012-10-17",
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

resource "aws_iam_policy" "SNSRead" {
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:ListTagsForResource",
                "sns:ListPhoneNumbersOptedOut",
                "sns:GetEndpointAttributes",
                "sns:GetTopicAttributes",
                "sns:GetPlatformApplicationAttributes",
                "sns:GetSubscriptionAttributes",
                "sns:GetSMSAttributes",
                "sns:CheckIfPhoneNumberIsOptedOut"
            ],
            "Resource": "${aws_sns_topic.2fa_swarm.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "Cloudwatch" {
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "2fa_sns_publish" {
    name = "2fa_sns_publish"
    roles = ["${aws_iam_role.2fa_lambda_manager.name}"]
    policy_arn = "${aws_iam_policy.SNSPublish.arn}"
}


resource "aws_iam_policy_attachment" "2fa_cloudwatch_manager" {
    name= "2fa_cloudwatch_manager"
    roles = ["${aws_iam_role.2fa_lambda_manager.name}"]
    policy_arn = "${aws_iam_policy.Cloudwatch.arn}"
}

resource "aws_iam_policy_attachment" "2fa_sns_read" {
    name = "2fa_sns_read"
    roles = ["${aws_iam_role.2fa_lambda_worker.name}"]
    policy_arn = "${aws_iam_policy.SNSRead.arn}"
}

resource "aws_iam_policy_attachment" "2fa_cloudwatch_worker" {
    name= "2fa_cloudwatch_worker"
    roles = ["${aws_iam_role.2fa_lambda_worker.name}"]
    policy_arn = "${aws_iam_policy.Cloudwatch.arn}"
}

resource "aws_lambda_function" "swarm_manager" {
    filename = "manager/build/build.zip"
    source_code_hash = "${filebase64sha256("manager/build/build.zip")}"
    function_name = "2fa_swarm_manager"
    role = "${aws_iam_role.2fa_lambda_manager.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "5"
    environment {
        variables = {
            SWARM_SNS_TOPIC_ARN = "${aws_sns_topic.2fa_swarm.arn}"
        }
    }
}

resource "aws_lambda_function" "swarm_worker" {
    filename = "worker/build/build.zip"
    source_code_hash = "${filebase64sha256("worker/build/build.zip")}"
    function_name = "2fa_swarm_worker"
    role = "${aws_iam_role.2fa_lambda_worker.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "5"
}

resource "aws_sns_topic_subscription" "2fa_swarm_target" {
    topic_arn = "${aws_sns_topic.2fa_swarm.arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.swarm_worker.arn}"
}
