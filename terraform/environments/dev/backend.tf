#--------------------------------------------------------------
# Remote State Configuration
#--------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "eks-tfstate-usama"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-terraform-locks"
    encrypt        = true
  }
}