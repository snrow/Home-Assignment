output "cluster_id" { value = aws_ecs_cluster.cluster.id }
output "ecs_sg_id" { value = aws_security_group.ecs_sg.id }
output "service_name" { value = aws_ecs_service.ms1.name }