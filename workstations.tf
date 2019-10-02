resource "aws_instance" "workstation" {
  connection = {
    type     = "winrm"
    password = "Fundamentals1"
    agent    = "false"
    insecure = true
    https    = false
  }

  ami                         = "ami-0583eb5712e67eb1c" # ${data.aws_ami.windows2016.id}
  instance_type               = "${var.workstation_type}"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.fundamentals_wkshp-subnet-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.fundamentals_wkshp.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.training_wkst_profile.name}"
  ebs_optimized               = true
  count                       = "${var.workstation_count}"
  depends_on                  = [
    aws_security_group_rule.ingress_allow_3389_tcp_all,
    aws_security_group_rule.ingress_allow_3389_udp_all,
    aws_security_group_rule.ingress_allow_winrm_tcp_all,
    aws_security_group_rule.ingress_allow_winrm_udp_all,
    aws_security_group_rule.linux_egress_allow_0
  ]
  user_data                   = <<-EOF
<powershell>

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

# set administrator password
cmd.exe /c net user Administrator Fundamentals1
cmd.exe /c net user chef Fundamentals1 /add /LOGONPASSWORDCHG:NO
cmd.exe /c net localgroup Administrators /add chef

# RDP
cmd.exe /c netsh advfirewall firewall add rule name="Open Port 3389" dir=in action=allow protocol=TCP localport=3389
cmd.exe /c reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm quickconfig '-transport:http'
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="3072"}'
cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTP" '@{Port="5985"}'
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5985 "Port 5985"
cmd.exe /c netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
cmd.exe /c netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm

cmd.exe /c wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE
cmd.exe /c wmic useraccount where "name='chef'" set PasswordExpires=FALSE

set-executionpolicy -executionpolicy unrestricted -force -scope LocalMachine

</powershell>

  EOF

  # provisioner "local-exec" {
  #   command = "sleep 30"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "if not exist \"c:\\hab\\user\\windows-workstation-chef\\config\\\" mkdir c:\\hab\\user\\windows-workstation-chef\\config"
  #   ]
  # }

  provisioner "file" {
    destination = "c:/hab/user/windows-workstation-chef/config/user.toml"
    content     = "${element(data.template_file.workstation_user_toml.*.rendered, count.index)}"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "hab license accept",
  #     "hab pkg install core/windows-service",
  #     "hab pkg exec core/windows-service install",
  #     "sc.exe start habitat",
  #     "waitfor svcstart /t 30 2>NUL",
  #     "hab svc load jvogt-fundamentals/windows-workstation-chef --channel unstable --strategy at-once"
  #   ]
  # }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.tag_customer}-${var.tag_project}_${random_id.instance_id.hex}_${var.tag_application}_workstation${count.index}"
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
  value = "Fundamentals1"
}

output "generated_password" {
  value = "Fundamentals1"
}

output "win_rdp" {
  value = ["${aws_instance.workstation.*.public_ip}"]
}