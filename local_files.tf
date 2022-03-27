########################### OUTPUT INVENTORY FOR ANSIBLE #########
resource "local_file" "inventory" {
  filename = "./inventory"
  content  = <<EOF
[syslogng]
${aws_instance.public_test_instance[0].public_dns}
${aws_instance.public_test_instance[1].public_dns}

[dns]
${aws_instance.public_test_instance[2].public_dns}

[client]
${aws_instance.public_test_instance[3].public_dns}

[mirror]
${aws_instance.public_test_instance[4].public_dns}

[multi:children]
syslogng
dns
client

[multi:vars]
ansible_become=True
ansible_become_method=sudo
ansible_become_user=root
ansible_python_interpreter=/usr/bin/python3
EOF
}
########################### OUTPUT INVENTORY FOR ANSIBLE #########

########################### HOSTS FILE FOR EACH INSTANCE #########

locals {
  hosts_append = <<-EOT
local-data: "syslog-0.tatooine.test.         IN        A      ${aws_instance.public_test_instance[0].private_ip}"
local-data: "syslog-1.tatooine.test.         IN        A      ${aws_instance.public_test_instance[1].private_ip}"
local-data: "dns.tatooine.test.              IN        A      ${aws_instance.public_test_instance[2].private_ip}"
local-data: "client.tatooine.test.           IN        A      ${aws_instance.public_test_instance[3].private_ip}"
local-data: "mirror.tatooine.test.           IN        A      ${aws_instance.public_test_instance[4].private_ip}"

local-data-ptr: "${aws_instance.public_test_instance[0].private_ip}            syslog-0.tatooine.test."
local-data-ptr: "${aws_instance.public_test_instance[1].private_ip}            syslog-1.tatooine.test."
local-data-ptr: "${aws_instance.public_test_instance[2].private_ip}            dns.tatooine.test."
local-data-ptr: "${aws_instance.public_test_instance[3].private_ip}            client.tatooine.test."
local-data-ptr: "${aws_instance.public_test_instance[4].private_ip}            mirror.tatooine.test."
EOT
}

resource "local_file" "hosts_append" {
  filename = "./dnshosts/hosts_append"
  content  = local.hosts_append
}
