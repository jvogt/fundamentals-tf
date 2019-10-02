resource "aws_instance" "target" {
  connection {
    user        = "${var.aws_centos_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  ami                    = "${data.aws_ami.centos.id}"
  instance_type          = "${var.linux_target_type}"
  key_name               = "${var.aws_key_pair_name}"
  subnet_id              = "${aws_subnet.fundamentals_wkshp-subnet-a.id}"
  vpc_security_group_ids = ["${aws_security_group.fundamentals_wkshp.id}"]
  ebs_optimized          = true
  count                  = "${var.workstation_count}"
  depends_on             = [
    aws_security_group_rule.ingress_allow_22_tcp_all,
    aws_security_group_rule.linux_egress_allow_0
  ]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_target${count.index}"
    )
  )}"

  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /hab/accepted-licenses",
      "mkdir -p ~/.hab/accepted-licenses",
      "sudo touch ~/.hab/accepted-licenses/habitat",
      "sudo touch /hab/accepted-licenses/habitat"
    ]
  }

  provisioner "habitat" {
    use_sudo = true
    service_type = "systemd"
    
    service {
      name = "jvogt-fundamentals/linux-target-chef"
      channel = "unstable"
      strategy = "at-once"
    }
  }
}

output "ssh_public_ip_targets" {
  value = ["${aws_instance.target.*.public_ip}"]
}
