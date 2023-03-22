variable "stage" {
  type        = string
  default     = ""
  description = "Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release'"
}

variable "name" {
  type        = string
  default     = "terraform"
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "region" {
  type        = string
  description = "AWS Region the S3 bucket should reside in"
}

