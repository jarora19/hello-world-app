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

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Change to your desired AZ
}

# Define ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

# Define task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "hello-world-app"
  container_definitions   = jsonencode([{
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
}

# Define security group for ECS
resource "aws_security_group" "ecs" {
  vpc_id = aws_vpc.main.id
  # Define inbound and outbound rules as needed
}

# Define outputs
#output "service_url" {
  #value = aws_ecs_service.app.load_balancer.first(1).dns_name
#}
