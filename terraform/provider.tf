provider "aws" {
  region = lookup(var.infrasharedprops, "region")
  shared_credentials_files = [ ".secrets.tfvars" ]
  profile = "production"
}
