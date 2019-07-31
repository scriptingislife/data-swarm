# Data Swarm

Send TCP data to a remote host from multiple IPs using a swarm of AWS Lambda functions.

## Try It Out

1. Install and configure [AWS CLI](https://aws.amazon.com/cli/)

2. `make pack && terraform apply`

3. Create an EC2 server and start a netcat listener on a port with `netcat -l 4444`. Make sure to open the port in the security group.

4. `aws lambda invoke --function-name data_swarm_manager --payload '{"host": "<my-ip>", "port": 4444, "body": "this is a test\r\n", "times": 10}' output.txt`