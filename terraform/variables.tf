variable "aws_region" { default = "ap-south-2" }
variable "app_name" { default = "cicd-demo-app" }
variable "ecr_image_uri" { type = string } # Passed by Jenkins at runtime
variable "container_port" { default = 3000 }
variable "desired_count" { default = 2 }
variable "task_cpu" { default = "256" } # 0.25 vCPU
variable "task_memory" { default = "512" } # 512 MiB
