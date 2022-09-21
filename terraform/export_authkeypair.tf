// Automatically generate the auth keypair files
resource "local_file" "tt_k8s_key_pub" {
 filename = "../ansible/tt_k8s_key.pub"
 file_permission = "0644"
 content = <<EOF
${tls_private_key.key-toptal_k8s_infra.public_key_openssh}
EOF
}

resource "local_file" "tt_k8s_key" {
 filename = "../ansible/tt_k8s_key"
 file_permission = "0400"
 content = <<EOF
${tls_private_key.key-toptal_k8s_infra.private_key_openssh}
EOF
}
