
terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "terraform-remote-tfstate-file"
    key    = "terraform.tfstate"
    #dynamodb_table = "state_lock"
  }

}