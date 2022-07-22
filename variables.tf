variable "bucket_name" {
  type    = string
  default = "my-app-andrei-ivanouski1"
}

variable "new_folder_A" {
  type    = string
  default = "A"
}

variable "new_folder_B" {
  type    = string
  default = "B"
}
variable "path_part_my_api_1" {
  description = "For lambda my-api-1"
  type        = string
  default     = "my-api-1"
}
variable "path_part_my_api_2" {
  description = "For lambda my-api-2"
  type        = string
  default     = "my-api-2"
}
variable "http_method" {
  description = "The HTTP method (GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY)."
  type        = string
  default     = "GET"
}
variable "request_parameters" {
  description = "Parameters of the method call. Query strings, for example."
  type        = map(any)
  default     = {}
}
variable "request_templates" {
  description = "Mapping of the request parameters of the method call."
  type        = map(any)
  default     = {}
}
/*
variable "lambda_invoke_arn" {
  description = "The arn (URI) of the lambda function the API Gateway is created for."
  type        = string
}
*/
variable "stage_name" {
  description = "The name of the stage. Part of the API resource's path."
  type        = string
  default     = "default"
}

variable "path_to_work_directory" {
  type    = string
  default = "/home/aivanouski1/study_notes/tf_notes/staitc_site"
}


