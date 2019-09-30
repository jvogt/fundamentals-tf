resource "aws_instance" "workstation" {
  connection = {
    type     = "winrm"
    password = "${random_string.random.result}"
    agent    = "false"
    insecure = true
    https    = false
  }

  ami                         = "ami-06665ce51c0917959" # ${data.aws_ami.windows2016.id}
  instance_type               = "${var.workstation_type}"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.fundamentals_wkshp-subnet-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.fundamentals_wkshp.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.training_wkst_profile.name}"
  ebs_optimized               = true
  count                       = "${var.workstation_count}"
  user_data                   = <<-EOF
<powershell>

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

# set administrator password
cmd.exe /c net user Administrator ${random_string.random.result}
cmd.exe /c net user chef ${random_string.random.result} /add /LOGONPASSWORDCHG:NO
cmd.exe /c net localgroup Administrators /add chef

cmd.exe /c wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE
cmd.exe /c wmic useraccount where "name='chef'" set PasswordExpires=FALSE

set-executionpolicy -executionpolicy unrestricted -force -scope LocalMachine

</powershell>

  EOF

  provisioner "local-exec" {
    command = "sleep 30"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir c:\\hab\\user\\windows-workstation-chef\\config"
    ]
  }

  provisioner "file" {
    destination = "c:/hab/user/windows-workstation-chef/config/user.toml"
    content     = "${element(data.template_file.workstation_user_toml.*.rendered, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "hab svc load jvogt-fundamentals/windows-workstation-chef --channel unstable --strategy at-once"
    ]
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_workstation"
    )
  )}"

}

data "template_file" "workstation_user_toml" {
  template = "${file("${path.module}/templates/workstation_user.toml.tpl")}"
  count = "${var.workstation_count}"
  vars {
    workstation_password = "${var.tag_application}PW${count.index}"
    chef_client_key = "${var.chef_client_key}"
    workstation_user = "workstation${count.index}"
    chef_server_url = "${var.chef_server_url}"
  }
}

output "win_password" {
  value = "${random_string.random.result}"
}

output "win_rdp" {
  value = "rdp://${element(concat(aws_instance.workstation.*.public_ip, list("")), 0)}"
}


output "win_rdp_t" {
  value = "rdp://${aws_instance.workstationt.public_ip}"
}