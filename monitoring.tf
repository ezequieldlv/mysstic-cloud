# ==========================================
# TOPIC SNS
# ==========================================
resource "aws_sns_topic" "alerts_topic" {
  name = "mysstic-alerts-topic"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.telegram_alerter.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telegram_alerter.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts_topic.arn
}

# ==========================================
# CLOUDWATCH ALARM
# ==========================================
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "EC2-CPU-Alta"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  
  statistic           = "Average"
  threshold           = 80.0 
  alarm_description   = "Alerta: CPU de EC2 por encima del 80%"
  
  alarm_actions       = [aws_sns_topic.alerts_topic.arn]

  dimensions = {
    InstanceId = aws_instance.mysstic_server.id 
  }
}