# S3 Remote State
terraform {
  backend "s3" {
    bucket         = "mehdi-tfstate-s3"
    key            = "mehdi-tfstate-s3"
    region         = "us-east-2"
    dynamodb_table = "mehdi-lock"
  }
}