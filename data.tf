
data "local_file" "public_key" {
  filename = "./creds/aws-key.pub"
}

# zip for lambda
data "archive_file" "api1" {
  type        = "zip"
  source_file = "scripts/api1.py"
  output_path = "scripts/api1.zip"
}
data "archive_file" "api2" {
  type        = "zip"
  source_file = "scripts/api2.py"
  output_path = "scripts/api2.zip"
}
