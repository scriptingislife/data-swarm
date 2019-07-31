provider "aws" {
    region = "us-east-1"
}

resource "aws_iam_role" "data_swarm_manager" {
    name = "data_swarm_manager"
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

resource "aws_iam_role" "data_swarm_worker" {
    name = "data_swarm_worker"
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

resource "aws_iam_policy" "LambdaInvoke" {
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "${aws_lambda_function.swarm_worker.arn}"
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

resource "aws_iam_policy_attachment" "cloudwatch_manager" {
    name= "data_swarm_cloudwatch_manager"
    roles = ["${aws_iam_role.data_swarm_manager.name}"]
    policy_arn = "${aws_iam_policy.cloudwatch_manager.arn}"
}

resource "aws_iam_policy_attachment" "data_swarm_cloudwatch_worker" {
    name= "data_swarm_cloudwatch_worker"
    roles = ["${aws_iam_role.data_swarm_worker.name}"]
    policy_arn = "${aws_iam_policy.cloudwatch_worker.arn}"
}

resource "aws_iam_policy_attachment" "data_swarm_invoke_worker" {
    name = "data_swarm_manager_invoke"
    roles = ["${aws_iam_role.data_swarm_manager.name}"]
    policy_arn = "${aws_iam_policy.LambdaInvoke.arn}"
}

resource "aws_lambda_function" "swarm_manager" {
    filename = "manager/build/build.zip"
    source_code_hash = "${filebase64sha256("manager/build/build.zip")}"
    function_name = "data_swarm_manager"
    role = "${aws_iam_role.data_swarm_manager.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "60"
    memory_size = 3008
    environment {
        variables {
            WORKER_FUNCTION_NAME = "${aws_lambda_function.swarm_worker.function_name}"
        }
    }
}

resource "aws_lambda_function" "swarm_worker" {
    filename = "worker/build/build.zip"
    source_code_hash = "${filebase64sha256("worker/build/build.zip")}"
    function_name = "data_swarm_worker"
    role = "${aws_iam_role.data_swarm_worker.arn}"
    handler = "main.handler"
    runtime = "python3.7"
    timeout = "1"
}
