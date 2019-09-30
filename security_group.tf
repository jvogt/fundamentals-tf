resource "aws_security_group" "fundamentals_wkshp" {
  name        = "fundamentals_wkshp_${random_id.instance_id.hex}"
  description = "Fundamentals Workshop"
  vpc_id      = "${aws_vpc.fundamentals_wkshp-vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_security_group"
    )
  )}"
}

//////////////////////////
// Base Linux Rules
resource "aws_security_group_rule" "ingress_allow_22_tcp_all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fundamentals_wkshp.id}"
}

resource "aws_security_group_rule" "ingress_allow_3389_tcp_all" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fundamentals_wkshp.id}"
}

resource "aws_security_group_rule" "ingress_allow_3389_udp_all" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fundamentals_wkshp.id}"
}

resource "aws_security_group_rule" "ingress_allow_winrm_tcp_all" {
  type              = "ingress"
  from_port         = 5985
  to_port           = 5986
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fundamentals_wkshp.id}"
}
resource "aws_security_group_rule" "ingress_allow_winrm_udp_all" {
  type              = "ingress"
  from_port         = 5985
  to_port           = 5986
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fundamentals_wkshp.id}"
}

# Egress: ALL
resource "aws_security_group_rule" "linux_egress_allow_0-65535_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fundamentals_wkshp.id}"
}
