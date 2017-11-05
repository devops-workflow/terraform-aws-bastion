// Bastion hosts public IPs
output "vpc_public_ips_bastion" {
  value = ["${aws_eip.eip_bastion.*.public_ip}"]
}
// Bastion host security group
output "vpc_sg_bastion" {
  value = "${aws_security_group.sg_bastion.id}"
}
