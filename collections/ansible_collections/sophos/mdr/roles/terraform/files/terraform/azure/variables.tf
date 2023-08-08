 variable "enabled" {
    type = bool
 }

 variable "name" {
    type = string
 }
 
 variable "namespace" {
    type = string
 }

 variable "environment" {
    type = string
 }

 variable "stage" {
    type = string
}

 variable "location" {
    type = string
 }

 variable "address_space" {
   type = list(string)
 }

 variable "subnet_count" {
   type = number
   default = 1
}

variable "max_subnet_count" {
   type = number
   default = 0
}