output "kubernetes-loadbalancer-instances" {
  value = {
    for node in aws_instance.k8s_loadbalancers:
      node.tags.Name => node.public_ip
  }

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
