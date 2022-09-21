// Automatically generate the ansible inventory file
resource "local_file" "inventory" {
 filename = "../ansible/inventory"
 file_permission = "0644"
 content = <<EOF
[k8s_loadbalancers]
%{ for node in aws_instance.k8s_loadbalancers ~}
${node.public_ip}
%{ endfor ~}

[k8s_masters]
%{ for node in aws_instance.k8s_masters ~}
${node.public_ip}
%{ endfor ~}

[k8s_workers]
%{ for node in aws_instance.k8s_workers ~}
${node.public_ip}
%{ endfor ~}

[all:vars]
ansible_ssh_user=ubuntu
ansible_ssh_private_key_file=./tt_k8s_key
ansible_ssh_common_args="-o StrictHostKeyChecking=no"
EOF
}
