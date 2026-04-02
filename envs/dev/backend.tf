terraform {
  backend "s3" {
    bucket         = "<YOUR_S3_BUCKET_NAME>"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<YOUR_DYNAMODB_TABLE_NAME>"
    encrypt        = true
  }
}