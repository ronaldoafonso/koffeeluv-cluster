
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

  tags = {
    Name        = "${var.cluster.name}-ecs-service"
    Environment = var.environment
  }
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

  tags = {
    Name        = "${var.cluster.name}-ecs-task-definition"
    Environment = var.environment
  }
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-ebs"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  image_id             = data.aws_ami.ecs_ami.id
  instance_type        = "m5.large"
  key_name             = var.asg.key_name
  security_groups      = var.asg.security_group_ids
  iam_instance_profile = "ecsInstanceRole"

  user_data = <<__EOF__
#!/bin/bash
echo ECS_CLUSTER=${var.cluster.name} >> /etc/ecs/ecs.config
__EOF__
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                      = "${var.cluster.name}_ecs_autoscaling_group"
  vpc_zone_identifier       = var.asg.subnet_ids
  launch_configuration      = aws_launch_configuration.ecs_launch_configuration.name
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 3
  health_check_grace_period = 300
  health_check_type         = "EC2"
}
