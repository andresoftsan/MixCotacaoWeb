# Variables para configuração da infraestrutura AWS
# Mix Cotação Web

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-central-1", "ap-southeast-1", "sa-east-1"
    ], var.aws_region)
    error_message = "Região deve ser uma das regiões AWS suportadas."
  }
}

variable "environment" {
  description = "Nome do ambiente (development, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment deve ser development, staging ou production."
  }
}

variable "project_name" {
  description = "Nome do projeto para tagging"
  type        = string
  default     = "mix-cotacao-web"
}

variable "domain_name" {
  description = "Nome do domínio para a aplicação (opcional)"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Senha master do banco de dados RDS"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Senha do banco deve ter pelo menos 8 caracteres."
  }
}

variable "db_username" {
  description = "Nome de usuário master do banco de dados"
  type        = string
  default     = "mixadmin"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "mixcotacao"
}

variable "instance_type" {
  description = "Tipo de instância EC2 para a aplicação"
  type        = string
  default     = "t3.small"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t4g.micro", "t4g.small", "t4g.medium"
    ], var.instance_type)
    error_message = "Tipo de instância deve ser um dos tipos t3 ou t4g suportados."
  }
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium",
      "db.t4g.micro", "db.t4g.small", "db.t4g.medium"
    ], var.db_instance_class)
    error_message = "Classe da instância deve ser uma das classes db.t3 ou db.t4g suportadas."
  }
}

variable "min_size" {
  description = "Número mínimo de instâncias no Auto Scaling Group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_size >= 1 && var.min_size <= 10
    error_message = "Tamanho mínimo deve estar entre 1 e 10."
  }
}

variable "max_size" {
  description = "Número máximo de instâncias no Auto Scaling Group"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_size >= 1 && var.max_size <= 10
    error_message = "Tamanho máximo deve estar entre 1 e 10."
  }
}

variable "desired_capacity" {
  description = "Número desejado de instâncias no Auto Scaling Group"
  type        = number
  default     = 2
  
  validation {
    condition     = var.desired_capacity >= 1 && var.desired_capacity <= 10
    error_message = "Capacidade desejada deve estar entre 1 e 10."
  }
}

variable "backup_retention_period" {
  description = "Período de retenção de backup em dias"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Período de retenção deve estar entre 0 e 35 dias."
  }
}

variable "allocated_storage" {
  description = "Armazenamento alocado para RDS em GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 1000
    error_message = "Armazenamento deve estar entre 20 e 1000 GB."
  }
}

variable "enable_deletion_protection" {
  description = "Habilitar proteção contra exclusão do Load Balancer"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Habilitar monitoramento detalhado"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Período de retenção dos logs em dias"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Período de retenção deve ser um dos valores permitidos pelo CloudWatch."
  }
}

variable "ssh_cidr_blocks" {
  description = "Blocos CIDR permitidos para acesso SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https" {
  description = "Habilitar HTTPS (requer certificado SSL)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN do certificado SSL (obrigatório se enable_https = true)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags adicionais para todos os recursos"
  type        = map(string)
  default     = {}
}

# Outputs das variáveis para validação
output "configuration_summary" {
  description = "Resumo da configuração"
  value = {
    aws_region          = var.aws_region
    environment         = var.environment
    project_name        = var.project_name
    instance_type       = var.instance_type
    db_instance_class   = var.db_instance_class
    min_size           = var.min_size
    max_size           = var.max_size
    desired_capacity   = var.desired_capacity
    backup_retention   = var.backup_retention_period
    allocated_storage  = var.allocated_storage
    enable_https       = var.enable_https
    enable_monitoring  = var.enable_monitoring
  }
}