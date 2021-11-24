# output "bastion_server_instance_id" {
#   description = "ID of the Bastion EC2 instance"
#   value       = join("\n", aws_instance.bastion-server.*.id)
# }