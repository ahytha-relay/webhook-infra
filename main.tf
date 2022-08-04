module "network" {
  source = "./modules/network"
}

resource "aws_security_group" "lb" {
  name = "example-alb-security-group"
  vpc_id = module.network.vpc_id 

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "default" {
  name = "example-lb"
  subnets = module.network.public_subnet_ids
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "hello_world" {
  name = "webhook-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = module.network.vpc_id
  target_type = "ip"
  health_check {
    healthy_threshold = 5
    interval = 30
  }
}

resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.default.id
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.hello_world.id
    type = "forward"
  }
}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecs_tasks_execution_role" {
  name               = "rn-ecs-task-execution-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_execution_role.json}"
}
resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = "${aws_iam_role.ecs_tasks_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "hello_world_task" {
  name = "webhook-task-security-group"
  vpc_id = module.network.vpc_id
  ingress {
    protocol = "tcp"
    from_port = 3000
    to_port = 3000
    security_groups = [aws_security_group.lb.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_private_dns_namespace" "ecs_dns_space" {
  name = "webhookdemo.relay"
  vpc = module.network.vpc_id
}

resource "aws_ecs_cluster" "main" {
  name = "webhook-cluster"
}

resource "aws_cloudwatch_log_group" "webhook_logs" {
  name = "/ecs/webhook-logs"
}

module "ecs_service" {
  source = "./modules/ecs_service"
  task_family = "webhook"
  service_name = "event-generator"
  log_group = {
    name = "/ecs/webhook-logs"
    region = "us-east-2"
  }
  container_image = "533137980844.dkr.ecr.us-east-1.amazonaws.com/webhook-event-generator:latest"
  container_port = 3000
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  desired_count = 2
  private_subnet_ids = module.network.private_subnet_ids
  security_group_id = aws_security_group.hello_world_task.id
  target_group_id = aws_lb_target_group.hello_world.id
  cluster_id = aws_ecs_cluster.main.id
  service_namespace_id = aws_service_discovery_private_dns_namespace.ecs_dns_space.id

  depends_on = [
    aws_lb_listener.hello_world
  ]
}

module "kafka" {
  source = "./modules/kafka"

  nickname = "webhook-msgbus"
  log_region = "us-east-2"
  service_namespace_id = aws_service_discovery_private_dns_namespace.ecs_dns_space.id
  service_namespace_name = "webhookdemo.relay"
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  private_subnet_ids = module.network.private_subnet_ids
  cluster_id = aws_ecs_cluster.main.id
}