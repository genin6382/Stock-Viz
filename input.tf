variable "aws_region"{
    description = "The region in which the resources will be created"
    default = "ap-southeast-2"
}
variable "aws_iam_policy_name"{
    description = "The name of the iam policy"
    default = "lambda-access-policy"
}
variable "aws_iam_role_name"{
    description = "The name of the iam role"
    default = "lambda-access-role"
}
variable "aws_lambda_function_name"{
    description ="The name of the lambda function to be created"
    default = "lambda-api-reader"
}
variable "aws_sqs_queue_name"{
    description = "The name of the sqs queue"
    default = "stock-price-queue"
}
variable "aws_sqs_dead_letter_queue_name"{
    description = "The name of the dead letter queue"
    default = "stock-price-dead-letter-queue"
}
variable "aws_lambda_processor_name"{
    description = "The name of the lambda function to process the messages"
    default = "lambda-api-processor"
}
variable "quicksight_user" {
  description = "QuickSight user name"
  type        = string
  default = "676206904741"
}