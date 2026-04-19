# ============================================
# CLOUDWATCH ALARMS
# ============================================

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# CloudWatch Alarm for USSD failures
resource "aws_cloudwatch_metric_alarm" "ussd_failure" {
  alarm_name          = "${var.project_name}-ussd-synthetic-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "USSDCheckFailure"
  namespace           = "AfriPay"
  period              = 60
  statistic           = "Sum"  # Fixed: changed from "p99" to "Sum"
  threshold           = 1
  alarm_description   = "USSD synthetic check failure detected"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for high response time (using Average instead of p99)
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.project_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TransactionLatency"
  namespace           = "AfriPay"
  period              = 60
  statistic           = "Average"  # Fixed: changed from "p99" to "Average"
  threshold           = 8000  # 8 seconds in milliseconds
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for database connection pool
resource "aws_cloudwatch_metric_alarm" "db_pool_high" {
  alarm_name          = "${var.project_name}-db-pool-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnectionPool"
  namespace           = "AfriPay"
  period              = 60
  statistic           = "Average"
  threshold           = 80  # 80% utilization
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for ECS CPU high
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    ClusterName = aws_ecs_cluster.afripay.name
    ServiceName = aws_ecs_service.app.name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = {
    Environment = var.environment
  }
}

# CloudWatch Alarm for RDS CPU high
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.afripay.identifier
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = {
    Environment = var.environment
  }
}
