#provider configuration
provider "aws"{
    region = var.aws_region
}
#creating a iam policy to attach to the role 
resource "aws_iam_policy" "lambda-policy"{
    name = var.aws_iam_policy_name
    description = "Allow lambda to access the given servies"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement=[
            {
                Effect = "Allow",
                Action = [
                    "s3:*",
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "sqs:*"
                ]
                Resource = "*"
            }
        ]
    })
}
#creating a iam role for lambda
resource "aws_iam_role" "lambda-role"{
    name = var.aws_iam_role_name
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "lambda.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })

}
#attaching the policy to the role
resource "aws_iam_role_policy_attachment" "lambda-policy-attachment"{
    role = aws_iam_role.lambda-role.name
    policy_arn = aws_iam_policy.lambda-policy.arn
}
#creating a zip file for the lambda function
data "archive_file" "lambda-zip"{
    type = "zip"
    source_file = "${path.module}/lambda/lambda-api-reader.py"
    output_path = "${path.module}/lambda/lambda-function.zip"
}
# Lambda layer
resource "aws_lambda_layer_version" "request_layer" {
    filename            = "lambda-layer.zip"
    layer_name          = "yfinance-layer-v5"  
    description         = "Layer containing requests package"
    compatible_runtimes = ["python3.9"]
}

# Lambda function
resource "aws_lambda_function" "lambda-function" {
    filename      = data.archive_file.lambda-zip.output_path
    function_name = var.aws_lambda_function_name
    role          = aws_iam_role.lambda-role.arn
    handler       = "lambda-api-reader.lambda_handler"
    runtime       = "python3.9"
    layers = [aws_lambda_layer_version.request_layer.arn]
    timeout     = 60
    memory_size = 512
    environment {
        variables = {
            PYTHONPATH = "/opt/python"
        }
    }
    depends_on = [
        aws_iam_role_policy_attachment.lambda-policy-attachment,
        aws_lambda_layer_version.request_layer
    ]
}
#creating a dead letter queue
resource "aws_sqs_queue" "dead_letter_queue"{
    name = var.aws_sqs_dead_letter_queue_name
    sqs_managed_sse_enabled = true
    message_retention_seconds = 86400
}
#creating a sqs queue
resource "aws_sqs_queue" "stock_queue"{
    name = var.aws_sqs_queue_name
    sqs_managed_sse_enabled = true
    message_retention_seconds = 86400
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = "*",
                Action = "sqs:SendMessage",
                Resource = "arn:aws:sqs:ap-southeast-2:676206904741:stock-price-queue",
                Condition = {
                    ArnEquals = {
                        "aws:SourceArn" = aws_lambda_function.lambda-function.arn
                    }
                }
            }
        ]
    })
    redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
        maxReceiveCount = 3
    })
}
#creating s3 bucket to store processed data
resource "aws_s3_bucket" "processed_data_bucket"{
    bucket = "vidhu-stock-data-bucket"
}
resource "aws_s3_bucket_policy" "processed_data_bucket_policy"{
    bucket = aws_s3_bucket.processed_data_bucket.id
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "lambda.amazonaws.com"
                },
                Action = "s3:*",
                Resource = "${aws_s3_bucket.processed_data_bucket.arn}/*"
            }
        ]
    })
}

#creating zip to upload to lambda
data "archive_file" "lambda-processor-zip"{
    type = "zip"
    source_file = "${path.module}/lambda/stock-data-processor.py"
    output_path = "${path.module}/lambda/lambda-function-process.zip"
}
#creating lambda function to process from sqs
resource "aws_lambda_function" "sqs-lambda-function"{
    function_name = var.aws_lambda_processor_name
    layers= [aws_lambda_layer_version.request_layer.arn]
    timeout = 60
    memory_size = 512
    filename = data.archive_file.lambda-processor-zip.output_path
    role = aws_iam_role.lambda-role.arn
    runtime = "python3.9"
    handler = "stock-data-processor.lambda_handler"
    environment {
      variables = {
        PYTHONPATH = "/opt/python"  
      }
    }
    depends_on = [
        aws_iam_role_policy_attachment.lambda-policy-attachment,
        aws_lambda_layer_version.request_layer
    ]
}
#creating a trigger for the lambda function
resource "aws_lambda_event_source_mapping" "sqs-lambda-trigger"{
    event_source_arn = aws_sqs_queue.stock_queue.arn
    function_name = aws_lambda_function.sqs-lambda-function.function_name
    depends_on = [ aws_lambda_function.sqs-lambda-function ]
}
#creating a cloudwatch event rule to trigger the lambda-api-reader every 3mins
resource "aws_cloudwatch_event_rule" "stock_price_schedule" {
  name                = "stock-price-schedule"
  description         = "Trigger stock price Lambda function every 2 minutes"
  schedule_expression = "rate(5 minutes)"
}

# EventBridge target - points to the Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.stock_price_schedule.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.lambda-function.arn
}

# Lambda permission to allow EventBridge to invoke the function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stock_price_schedule.arn
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# QuickSight service role for giving quicksight access to s3
resource "aws_iam_role" "quicksight_role" {
  name = "quicksight-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })
}

# Policy to allow QuickSight to read from S3
resource "aws_iam_role_policy" "quicksight_policy" {
  name = "quicksight-s3-policy"
  role = aws_iam_role.quicksight_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::vidhu-stock-data-bucket",
          "arn:aws:s3:::vidhu-stock-data-bucket/*"
        ]
      }
    ]
  })
}

# QuickSight Data Source
resource "aws_quicksight_data_source" "s3_source" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_source_id = "stock-data-source"
  name           = "Stock Data Source"
  type          = "S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = "vidhu-stock-data-bucket"
        key    = "manifest.json"
      }
    }
  }
}

# QuickSight Dataset
resource "aws_quicksight_data_set" "stock_dataset" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_set_id    = "stock-price-dataset"
  name           = "Stock Price Dataset"
  import_mode    = "SPICE"

  permissions {
    actions = [
        "quicksight:DescribeDataSet",
        "quicksight:DescribeDataSetPermissions",
        "quicksight:PassDataSet",
        "quicksight:DescribeIngestion",
        "quicksight:ListIngestions",
        "quicksight:UpdateDataSet",
        "quicksight:DeleteDataSet",
        "quicksight:CreateIngestion",
        "quicksight:CancelIngestion",
        "quicksight:UpdateDataSetPermissions"
  ]
    principal = "arn:aws:quicksight:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:user/default/${var.quicksight_user}"
  }

  physical_table_map {
    physical_table_map_id = "stock-data-table"
    s3_source {
      data_source_arn = aws_quicksight_data_source.s3_source.arn
      input_columns {
        name = "ticker"
        type = "STRING"
      }
      input_columns {
        name = "price"
        type = "STRING"
      }
      input_columns {
        name = "timestamp"
        type = "STRING"
      }
      input_columns {
        name = "currency"
        type = "STRING"
      }
      upload_settings {
        format = "JSON"
        start_from_row = 1
        contains_header = true
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "stock-logical-table"
    alias = "stock_data"
    source {
      physical_table_id = "stock-data-table"
    }
  }
}
