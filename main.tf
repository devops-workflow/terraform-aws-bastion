/**
 * Bastion host in VPC Terraform Module
 * =====================
 *
 * Usage:
 * ------
 *
 *     module "bastion" {
 *       source              = "../tf_bastion"
 *       environment         = "${var.environment}"
 *       name                = "${var.name}"
 *       aws_base_ami        = "ami-9be6f38c" # "Amazon Linux AMI" # 2016.09.1 (HVM)
 *       availability_zones  = "${module.vpc.availability_zones}"
 *       # Whitelist Internal (Routing, SG)
 *       private_cidrs       = ["${var.corp_vpn_cidr}"]
 *       # Whitelist External, public cidrs (SG)
 *       public_cidrs        = []
 *       public_subnet_ids   = "${module.vpc.external_subnets}"
 *       route53_zone        = "${module.dns_public.route53_zone_id}"
 *       ssh_key_name        = "${var.ssh_key_name}"
 *       vpc_id              = "${module.vpc.id}"
 *     }
**/

# Create EC2 Instance
resource "aws_instance" "inst_bastion" {
  count             = "${length(var.availability_zones)}"
  ami               = "${var.aws_base_ami}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  instance_type     = "${var.nat_instance_type}"
  key_name          = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${aws_security_group.sg_bastion.id}"]
  subnet_id         = "${element(var.public_subnet_ids, count.index)}"
  associate_public_ip_address = true
  source_dest_check = false

  tags = "${ merge(
    var.tags,
    map("Name", var.namespaced ?
     format("%s-%s-bastion-%03d", var.environment, var.name, count.index) :
     format("%s-bastion-%03d", var.name, count.index) ),
    map("Environment", var.environment),
    map("Terraform", "true") )}"
}

resource "aws_eip" "eip_bastion" {
  count       = "${length(var.availability_zones)}"
  instance    = "${element(aws_instance.inst_bastion.*.id, count.index)}"
  vpc         = true
  depends_on  = ["aws_instance.inst_bastion"]
}

# Use security group module ?
resource "aws_security_group" "sg_bastion" {
  name = "${var.environment}-${var.name}-bastion"
  description = "Bastion server group whitelist, allow incoming SSH from Corporate IPs"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.public_cidrs}", "${var.private_cidrs}"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["${var.public_cidrs}", "${var.private_cidrs}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${ merge(
    var.tags,
    map("Name", var.namespaced ?
     format("%s-%s-bastion", var.environment, var.name) :
     format("%s-bastion", var.name) ),
    map("Environment", var.environment),
    map("Terraform", "true") )}"
}

# Add DNS record
# TODO: add aws_route53_record.bastion.*.fqdn to output
# Host and DNS index may not match. How to ensure they do?
# Use lookup(map)? index (list),
# eip.instance (ID) & private_ip
# instance.private_ip
# May need to get from tags? How? data filter by tag or instance ID and lookup tag
# Data can only return 1 thing. How to mange multiple items?
#data "aws_instance" "bastion" {}

# FIX: Issue calculating count before eip exists
resource "aws_route53_record" "bastion" {
  count   = "${length(aws_eip.eip_bastion.*.public_ip)}"
  zone_id = "${var.route53_zone}"
  name    = "${format("bastion-%02d", count.index)}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_eip.eip_bastion.*.public_ip, count.index)}"]
  depends_on = ["aws_eip.eip_bastion"]
}
