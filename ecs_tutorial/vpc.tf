resource "aws_vpc" "TF_week19" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "VPC for ecs_week19"
  }
}