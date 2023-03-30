variable "do_token" {
  type      = string
  sensitive = true
}

variable "backend_instance_count" {
  type    = number
  default = 3
}

variable "docker_host" {
  type = string
}



variable "do_region" {
  type    = string
  default = "sgp1"
}

variable "do_image" {
  type    = string
  default = "ubuntu-20-04-x64"
}

variable "do_size" {
  type    = string
  default = "s-1vcpu-512mb-10gb"
}

