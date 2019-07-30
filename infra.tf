provider "aws" {
    region = "us-east-1"
}

resource "aws_sns_topic" "2fa_swarm" {
    name = "2fa-swarm"
}

resource "aws_dynamodb_table" "2fa_db_table" {
    name = "2FA-Swarm"
    hash_key = "uuid"
    read_capacity = 5
    write_capacity = 5

    attribute {
        name = "uuid"
        type = "S"
    }
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

resource "aws_iam_policy" "cloudwatch_manager" {
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

resource "aws_iam_policy" "cloudwatch_worker" {
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


resource "aws_iam_policy" "dynamodb_worker" {
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "dynamodb:PutItem",
            "Resource": "${aws_dynamodb_table.2fa_db_table.arn}"
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
    policy_arn = "${aws_iam_policy.cloudwatch_manager.arn}"
}

resource "aws_iam_policy_attachment" "2fa_cloudwatch_worker" {
    name= "2fa_cloudwatch_worker"
    roles = ["${aws_iam_role.2fa_lambda_worker.name}"]
    policy_arn = "${aws_iam_policy.cloudwatch_worker.arn}"
}

resource "aws_iam_policy_attachment" "2fa_db_worker" {
    name = "2fa_db_worker"
    roles = ["${aws_iam_role.2fa_lambda_worker.name}"]
    policy_arn = "${aws_iam_policy.dynamodb_worker.arn}"
}

resource "aws_lambda_function" "swarm_manager" {
    filename = "manager/build/build.zip"
    source_code_hash = "${filebase64sha256("manager/build/build.zip")}"
    function_name = "2fa_swarm_manager"
    role = "${aws_iam_role.2fa_lambda_manager.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "60"
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
    environment {
        variables = {
            DB_NAME = "${aws_dynamodb_table.2fa_db_table.name}"
        }
    }
}

resource "aws_sns_topic_subscription" "2fa_swarm_target" {
    topic_arn = "${aws_sns_topic.2fa_swarm.arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.swarm_worker.arn}"
}

resource "aws_lambda_permission" "sns_trigger" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.swarm_worker.arn}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.2fa_swarm.arn}"
}