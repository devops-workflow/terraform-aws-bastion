
// Standard Variables

variable "name" {
  description = "Name"
}
variable "environment" {
  description = "Environment (ex: dev, qa, stage, prod)"
}
variable "namespaced" {
  description = "Namespace all resources (prefixed with the environment)?"
  default     = true
}
variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

// Module specific Variables

variable "aws_base_ami" {
  description = "Amazon Linux AMI"
}
variable "nat_instance_type" {
  description = "NAT/bastion instance type"
  default     = "t2.micro"
}
variable "num_of_azs" {
  description = "Number of multipe AZ to be utilized"
  default     = 2
}
variable "ssh_key_name" {
  description = "SSH key pair name in AWS (must already exist)"
  default     = ""
}
variable "availability_zones" {
  type        = "list"
}
variable "public_subnet_ids" {
  description = "Public subnets list"
  type        = "list"
}
variable "private_cidrs" {
  type        = "list"
  description = "Internal CIDRs - range of private CIDRs that can connect to resources inside the VPC"
  default     = ["10.0.0.0/8"]
}
variable "public_cidrs" {
  type        = "list"
  description = "Trusted CIDRs - range of public Internet CIDRs that can connect to the public resources of the VPC"
}
variable "route53_zone" {
  description = "Route53 Zone ID to add Bastion DNS to"
}
variable "vpc_id" {
  description = "AWS VPC ID to put bastion in"
}
