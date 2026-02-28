data "aws_caller_identity" "current" {}
output "alb_dns_name" { value = aws_lb.main.dns_name }
output "alb_url" { value = "http://${aws_lb.main.dns_name}" }
output "ecs_cluster_name" { value = aws_ecs_cluster.main.name }
output "ecs_service_name" { value = aws_ecs_service.app.name }
output "ecr_repository_url" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}"
}


