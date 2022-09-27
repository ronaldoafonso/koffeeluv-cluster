
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster.name

  tags = {
    Name        = var.cluster.name
    Environment = var.environment
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.service.name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.service.desired_count
  launch_type     = "EC2"
}


resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = var.task_definition.family
  requires_compatibilities = ["EC2"]
  execution_role_arn       = "arn:aws:iam::${var.task_definition.account}:role/ecsTaskExecutionRole"
  container_definitions    = <<__END__
[
  {
    "image": "${var.task_definition.image}",
    "name": "${var.task_definition.name}",
    "memory": ${var.task_definition.memory},
    "networkMode": "${var.task_definition.network_mode}",
    "portMappings": [
      {
        "containerPort": ${var.task_definition.container_port},
        "hostPort": ${var.task_definition.host_port}
      }
    ]
  }
]
__END__
}
