terraform {
  backend "s3" {
    bucket = "terraform-state1212"
    key    = "project4/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}
