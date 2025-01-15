output "aws_role_arn"{
    value = aws_iam_role.lambda-role.arn
}
output "aws_lambda_function_name"{
    value = aws_lambda_function.lambda-function.function_name
}
output "aws_sqs_queue_url"{
    value = aws_sqs_queue.stock_queue.url
}
output "aws_dead_letter_queue_url"{
    value = aws_sqs_queue.dead_letter_queue.url
}
output "aws_s3_bucket_name"{
    value = aws_s3_bucket.processed_data_bucket.bucket
}
output "aws_lambda_processor_name"{
    value = aws_lambda_function.sqs-lambda-function.function_name
}
output "aws_cloudwatch_event_rule_name"{
    value = aws_cloudwatch_event_rule.stock_price_schedule.name
}
output "aws_lambda_layer_arn"{
    value = aws_lambda_layer_version.request_layer.arn
}
output "quicksight_datasource_arn" {
  value = aws_quicksight_data_source.s3_source.arn
}