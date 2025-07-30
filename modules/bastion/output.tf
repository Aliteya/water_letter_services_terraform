output "network_interface_id" {
    value = aws_network_interface.network_interface.id
}

output "nat_instance_sg_id" {
    value = aws_security_group.nat_instance_sg.id
}

output "bastion_public_ip" {
    description = "Public IP address of the bastion host."
    value = aws_eip.ec2_bastion_host_eip.public_ip
}