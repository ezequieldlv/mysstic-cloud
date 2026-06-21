# ==========================================
# 1. IAM ROLE LAMBDA
# ==========================================
resource "aws_iam_role" "lambda_role" {
  name = "mysstic_lambda_telegram_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==========================================
# 2. LAMBDA FUNCTION
# ==========================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/alert.py"
  output_path = "${path.module}/lambda/alert.zip"
}

resource "aws_lambda_function" "telegram_alerter" {
# checkov:skip=CKV_AWS_116: "Dead Letter Queue no requerido para alertas simples"
# checkov:skip=CKV_AWS_50: "X-Ray tracing desactivado por costos (FinOps)"
# checkov:skip=CKV_AWS_173: "KMS CMK para variables de entorno omitido (FinOps)"
# checkov:skip=CKV_AWS_272: "Code signing no requerido en fase Dev"
# checkov:skip=CKV_AWS_117: "Lambda no requiere acceso a VPC para enviar Telegrams"
# checkov:skip=CKV_AWS_115: "Concurrent execution limit omitido"

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "Telegram-Alerter-MyssTic"
  role             = aws_iam_role.lambda_role.arn
  handler          = "alert.lambda_handler" 
  runtime          = "python3.12"  
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN = var.telegram_token
      TELEGRAM_CHAT_ID   = var.telegram_chat_id
    }
  }
}

# ==========================================
# 3. SNS TOPIC & CLOUDWATCH
# ==========================================
resource "aws_sns_topic" "alerts" {
# checkov:skip=CKV_AWS_26: "SNS topic solo maneja metricas de CPU no sensibles. KMS omitido (FinOps)"

  name = "mysstic-alerts-topic"
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.telegram_alerter.arn
}

resource "aws_lambda_permission" "sns_allow" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telegram_alerter.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "EC2-CPU-Alta"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  
  statistic           = "Average"
  threshold           = 80.0 
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id
  }
}