resource "aws_service_discovery_service" "main" {
  name = var.service_name
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

resource "aws_ecs_task_definition" "main" {
  family = "${var.task_family}"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 1024
  memory = 2048
  execution_role_arn = var.execution_role_arn
  container_definitions = jsonencode([
    {
      "image": var.container_image,
      "cpu": 1024,
      "memory": 2048,
      "name": var.service_name,
      "networkMode": "awsvpc",
      "portMappings": [
        {
          "containerPort": var.container_port,
          "hostPort": var.container_port
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": var.log_group.name,
          "awslogs-region": var.log_group.region,
          "awslogs-stream-prefix": var.service_name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name = var.service_name
  cluster = var.cluster_id 
  task_definition = aws_ecs_task_definition.main.arn
  desired_count = var.desired_count
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [var.security_group_id]
    subnets = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = var.target_group_id
    container_name = var.service_name
    container_port = var.container_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
  }
}
