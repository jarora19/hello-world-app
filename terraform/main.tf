# main.tf

provider "aws" {
  region = "us-east-1"  # Change to your desired AWS region
}

# Define VPC, subnets, security groups, etc.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Change to your desired AZ
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"  # Specify a different Availability Zone from subnet_a
}

# Define ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

# Define task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "hello-world-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = jsonencode([{
    name  = "hello-world-app"
    image = "jatin19/node-app:v1"  # Change to your Docker image URL
    memory = 256
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])
}

# Define ECS service
resource "aws_ecs_service" "app" {
  name            = "hello-world-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "hello-world-app"
    container_port   = 3000
  }
}

# Define security group for ECS
resource "aws_security_group" "ecs" {
  vpc_id = aws_vpc.main.id
  # Define inbound and outbound rules as needed
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

output "service_url" {
  value = aws_lb.my_lb.dns_name
}

# Define outputs
#output "service_url" {
  #value = aws_ecs_service.app.load_balancer.first(1).dns_name
#}
