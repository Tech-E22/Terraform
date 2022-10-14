# Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20.0"
    }
  }
}
resource "aws_ecs_cluster" "cluster" {
  name = "week19-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}


module "ecs-fargate" {
  source  = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix        = "ecs-fargate-week19"
  vpc_id             = aws_vpc.TF_week19.id
  private_subnet_ids = [aws_subnet.private_subnet_1a_week19.id, aws_subnet.private_subnet_1b_week19.id]

  cluster_id = aws_ecs_cluster.cluster.id

  task_container_image   = "centos:latest"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

  load_balanced = false

  target_groups = [
    {
      target_group_name = "tg-fargate-week19"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = "test"
    Project     = "week19"
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "docker" {}