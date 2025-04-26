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

variable "internet" {
    type = string
    description = "Internet connectivity of the instances. Set to \"public\" to use a public IP address, \"nat\" to use a NAT gateway, or \"none\" for no connectivity."
    default = "public"
    validation {
        condition = contains(["public", "nat", "none"], var.internet)
        error_message = "Must be one of \"public\", \"nat\", or \"none\"."
    }
}
