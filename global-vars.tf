##global variables

variable "organization" {
  type        = string
  description = "Organization Name"
  default     = "default"
}

variable "tags" {
  type    = list(map(string))
  default = []
}
