resource "aws_service_discovery_service" "zookeeper" {
  name = "${var.nickname}-zookeeper"
  dns_config {
    namespace_id = var.service_namespace_id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 5
  }
}

resource "aws_service_discovery_service" "kafka" {
  name = "${var.nickname}-kafka"
  dns_config {
    namespace_id = var.service_namespace_id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 5
  }
}

resource "aws_cloudwatch_log_group" "default" {
  name = "/kafka/${var.nickname}"
}

resource "aws_ecs_task_definition" "zookeeper" {
  family = var.nickname
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 1024
  memory = 2048
  execution_role_arn = var.execution_role_arn
  container_definitions = jsonencode([
    {
      "image": "533137980844.dkr.ecr.us-east-1.amazonaws.com/confluentinc/cp-zookeeper:latest",
      "cpu": 1024,
      "memory": 2048,
      "name": "${var.nickname}-zookeeper",
      "networkMode": "awsvpc",
      "portMappings": [
        {
          "containerPort": 2181,
          "hostPort": 2181
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": aws_cloudwatch_log_group.default.name,
          "awslogs-region": var.log_region,
          "awslogs-stream-prefix": "zookeeper/"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "zookeeper" {
  name = "${var.nickname}-zookeeper"
  cluster = var.cluster_id 
  task_definition = aws_ecs_task_definition.main.arn
  # desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    security_groups = []
    subnets = var.private_subnet_ids
  }
  service_registries {
    registry_arn = aws_service_discovery_service.zookeeper.arn
  }
}

resource "aws_ecs_task_definition" "kafka" {
  family = var.nickname
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 1024
  memory = 2048
  execution_role_arn = var.execution_role_arn
  container_definitions = jsonencode([
    {
      "image": "533137980844.dkr.ecr.us-east-1.amazonaws.com/confluentinc/cp-kafka:latest",
      "cpu": 1024,
      "memory": 2048,
      "name": "${var.nickname}-kafka",
      "networkMode": "awsvpc",
      "portMappings": [
        {
          "containerPort": 9092,
          "hostPort": 9092
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": aws_cloudwatch_log_group.default.name,
          "awslogs-region": var.log_region,
          "awslogs-stream-prefix": "kafka/"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name = "${var.nickname}-kafka"
  cluster = var.cluster_id 
  task_definition = aws_ecs_task_definition.main.arn
  # desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    security_groups = []
    subnets = var.private_subnet_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.kafka.arn
  }
}
