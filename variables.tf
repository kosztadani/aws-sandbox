variable "s3_bucket" {
    type = string
    description = "The S3 bucket used by this environment."
}

variable "instances" {
    type = number
    description = "Number of instances to create."
    default = 1
}

variable "run" {
    type = bool
    description = "Can be set to false to destroy all instances."
    default = true
}
