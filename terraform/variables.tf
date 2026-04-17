
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"  # Closest to Africa
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "afripay"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "az_count" {
  description = "Number of Availability Zones"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "afripay"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "afripay_admin"
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Days to retain database backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "app_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 512
}

variable "desired_task_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "max_task_count" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 10
}
