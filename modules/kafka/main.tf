
resource "aws_security_group" "kafka_security_group" {
  name = "kafka-security-group"
  vpc_id = var.vpc_id 

  ingress_cidr_blocks = var.private_subnet_cidr_blocks
  ingress_rules = ["kafka-broker-tcp", "kafka-broker-tls-tcp"]
}

module "msk_kafka_cluster" {
  source = "clowdhaus/msk-kafka-cluster/aws"
  name = var.name
  kafka_version = "2.8.0"
  number_of_broker_nodes = 2
  enhanced_monitoring = "PER_TOPIC_PER_PARTITION"
  broker_node_client_subnets = var.private_subnets
  broker_node_ebs_volume_size = 20
  broker_node_instance_type = "kafka.t3.small"
  broker_node_security_groups = var.broker_node_security_groups

}

# resource "aws_service_discovery_service" "zookeeper" {
#   name = "${var.nickname}-zookeeper"
#   dns_config {
#     namespace_id = var.service_namespace_id
#     routing_policy = "MULTIVALUE"
#     dns_records {
#       ttl = 10
#       type = "A"
#     }
#   }
#   health_check_custom_config {
#     failure_threshold = 5
#   }
# }

# resource "aws_service_discovery_service" "kafka" {
#   name = "${var.nickname}-kafka"
#   dns_config {
#     namespace_id = var.service_namespace_id
#     routing_policy = "MULTIVALUE"
#     dns_records {
#       ttl = 10
#       type = "A"
#     }
#   }
#   health_check_custom_config {
#     failure_threshold = 5
#   }
# }

# resource "aws_cloudwatch_log_group" "default" {
#   name = "/kafka/${var.nickname}"
# }

# resource "aws_ecs_task_definition" "zookeeper" {
#   family = "${var.nickname}-zookeeper"
#   network_mode = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu = 1024
#   memory = 2048
#   execution_role_arn = var.execution_role_arn
#   container_definitions = jsonencode([
#     {
#       "image": "533137980844.dkr.ecr.us-east-1.amazonaws.com/confluentinc/cp-zookeeper:latest",
#       "cpu": 1024,
#       "memory": 2048,
#       "name": "${var.nickname}-zookeeper",
#       "networkMode": "awsvpc",
#       "portMappings": [
#         {
#           "containerPort": 2181,
#           "hostPort": 2181
#         }
#       ],
#       "logConfiguration": {
#         "logDriver": "awslogs",
#         "options": {
#           "awslogs-group": aws_cloudwatch_log_group.default.name,
#           "awslogs-region": var.log_region,
#           "awslogs-stream-prefix": "zookeeper"
#         }
#       },
#       "environment": [
#         {
#           "name": "ZOOKEEPER_CLIENT_PORT",
#           "value": "2181"
#         },
#         {
#           "name": "ZOOKEEPER_TICK_TIME",
#           "value": "200"
#         },
#       ]
#     }
#   ])
# }

# resource "aws_ecs_service" "zookeeper" {
#   name = "${var.nickname}-zookeeper"
#   cluster = var.cluster_id 
#   task_definition = aws_ecs_task_definition.zookeeper.arn
#   desired_count = 1
#   launch_type = "FARGATE"

#   network_configuration {
#     security_groups = []
#     subnets = var.private_subnet_ids
#   }
#   service_registries {
#     registry_arn = aws_service_discovery_service.zookeeper.arn
#   }
# }

# resource "aws_ecs_task_definition" "kafka" {
#   family = "${var.nickname}-kafka"
#   network_mode = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu = 1024
#   memory = 2048
#   execution_role_arn = var.execution_role_arn
#   container_definitions = jsonencode([
#     {
#       "image": "533137980844.dkr.ecr.us-east-1.amazonaws.com/confluentinc/cp-kafka:latest",
#       "cpu": 1024,
#       "memory": 2048,
#       "name": "${var.nickname}-kafka",
#       "networkMode": "awsvpc",
#       "portMappings": [
#         {
#           "containerPort": 9092,
#           "hostPort": 9092
#         }
#       ],
#       "logConfiguration": {
#         "logDriver": "awslogs",
#         "options": {
#           "awslogs-group": aws_cloudwatch_log_group.default.name,
#           "awslogs-region": var.log_region,
#           "awslogs-stream-prefix": "kafka"
#         }
#       }
#       "environment": [
#         {
#           "name": "KAFKA_BROKER_ID",
#           "value": "1"
#         },
#         {
#           "name": "KAFKA_ZOOKEEPER_CONNECT",
#           "value": "${var.nickname}-zookeeper.${var.service_namespace_name}:2181"
#         },
#         {
#           "name": "KAFKA_LISTENERS",
#           "value": "PLAINTEXT_HOST://0.0.0.0:9029,INTERNAL://:9092"
#         },
#         {
#           "name": "KAFKA_LISTENERS_SECURITY_PROTOCOL_MAP",
#           "value": "PLAINTEXT_HOST:PLAINTEXT,INTERNAL:PLAINTEXT"
#         },
#         {
#           "name": "KAFKA_ADVERTISED_LISTENERS",
#           "value": "PLAINTEXT_HOST://localhost:9092,INTERNAL://kafka:9092"
#         },
#         {
#           "name": "KAFKA_INTER_BROKER_LISTENER_NAME",
#           "value": "INTERNAL"
#         },
#         {
#           "name": "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR",
#           "value": "1"
#         },
#         {
#           "name": "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR",
#           "value": "1"
#         },
#         {
#           "name": "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR",
#           "value": "1"
#         }
#       ]
#     }
#   ])
# }

# resource "aws_ecs_service" "main" {
#   name = "${var.nickname}-kafka"
#   cluster = var.cluster_id 
#   task_definition = aws_ecs_task_definition.kafka.arn
#   desired_count = 1
#   launch_type = "FARGATE"

#   network_configuration {
#     security_groups = []
#     subnets = var.private_subnet_ids
#   }

#   service_registries {
#     registry_arn = aws_service_discovery_service.kafka.arn
#   }
# }
