output "cluster_id" { value = aws_ecs_cluster.cluster.id }
output "ecs_sg_id" { value = aws_security_group.ecs_sg.id }
output "frontend_service_service_name" { value = aws_ecs_service.frontend_service.name }
output "queue_worker_service_service_name" { value = aws_ecs_service.queue_worker_service.name }