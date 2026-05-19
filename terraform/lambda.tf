# ==========================================
# ZIP PYTHON CODE
# ==========================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/alert.py"
  output_path = "${path.module}/lambda/alert.zip"
}

# ==========================================
# SERVERLESS FUNCTION (TELEGRAM ALERTER)
# ==========================================
resource "aws_lambda_function" "telegram_alerter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "Telegram-Alerter-MyssTic"
  role             = aws_iam_role.lambda_exec_role.arn
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