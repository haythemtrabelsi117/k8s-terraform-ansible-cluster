output "kubernetes-app-loadbalancer" {
value = aws_lb.lb-toptal_k8s_infra.dns_name
}

output "kubernetes-master-instances" {
  value = {
    for node in aws_instance.k8s_masters:
      node.tags.Name => node.public_ip
  }

}

output "kubernetes-worker-instances" {
  value = {
    for node in aws_instance.k8s_workers:
      node.tags.Name => node.public_ip
  }
}

