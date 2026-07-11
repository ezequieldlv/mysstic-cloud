output "ec2_security_group_id" {
  value = aws_security_group.ec2_sg.id
}
output "ec2_public_ip" {
  value = aws_eip.server_ip.public_ip
}
output "ec2_instance_id" {
  value = aws_instance.server.id
}
