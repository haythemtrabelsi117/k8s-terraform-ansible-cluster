// Automatically generate the ansible inventory file
resource "local_file" "inventory" {
 filename = "../ansible/inventory"
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
EOF
}
