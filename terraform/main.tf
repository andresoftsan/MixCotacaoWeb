# Mix Cotação Web - Infraestrutura AWS com Terraform
# Execute: terraform init && terraform plan && terraform apply

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configurar provider AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "MixCotacaoWeb"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Variáveis
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "mixcotacao.seudominio.com.br"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "MixGestao2025!Database"
}

# Dados existentes
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC e Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "mix-cotacao-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "mix-cotacao-igw"
  }
}

resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "mix-cotacao-public-${count.index + 1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "mix-cotacao-private-${count.index + 1}"
    Type = "Private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "mix-cotacao-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "mix-cotacao-alb-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "mix-cotacao-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name_prefix = "mix-cotacao-app-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restringir para seu IP em produção
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "mix-cotacao-app-sg"
  }
}

resource "aws_security_group" "db" {
  name_prefix = "mix-cotacao-db-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  tags = {
    Name = "mix-cotacao-db-sg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "mix-cotacao-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "mix-cotacao-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "mix-cotacao-db"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "mixcotacao"
  username = "mixadmin"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true # Alterar para false em produção
  
  tags = {
    Name = "mix-cotacao-database"
  }
}

# Key Pair para EC2
resource "aws_key_pair" "main" {
  key_name   = "mix-cotacao-key"
  public_key = file("~/.ssh/id_rsa.pub") # Gere sua chave SSH antes
}

# IAM Role para EC2
resource "aws_iam_role" "ec2_role" {
  name = "mix-cotacao-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "mix-cotacao-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "mix-cotacao-ec2-policy"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# User Data Script
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    database_url = "postgresql://${aws_db_instance.main.username}:${var.db_password}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  }))
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "mix-cotacao-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.main.key_name
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  user_data = local.user_data
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "mix-cotacao-app"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "mix-cotacao-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "mix-cotacao-asg"
    propagate_at_launch = false
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "mix-cotacao-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = false # Alterar para true em produção
  
  tags = {
    Name = "mix-cotacao-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "mix-cotacao-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "mix-cotacao-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Route 53 (opcional - configurar se tiver domínio)
# resource "aws_route53_zone" "main" {
#   name = var.domain_name
# }

# resource "aws_route53_record" "app" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"
  
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/mix-cotacao"
  retention_in_days = 14
  
  tags = {
    Name = "mix-cotacao-logs"
  }
}

# Outputs
output "load_balancer_dns" {
  description = "DNS name do Load Balancer"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "Endpoint do banco RDS"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "database_url" {
  description = "URL completa do banco de dados"
  value       = "postgresql://${aws_db_instance.main.username}:${var.db_password}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "application_url" {
  description = "URL da aplicação"
  value       = "http://${aws_lb.main.dns_name}"
}