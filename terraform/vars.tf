variable "infrasharedprops" {
  type = map
  default = {
    region = "us-east-1"
    vpc = "vpc-toptal_k8s_infra"
    ami = "ami-052efd3df9dad4825"
    itype = "t2.micro"
    publicip = true
    authkeypair = "ht-pko"
    secgroupname = "tt-k8s-cluster-security-group"
    }
}

variable "k8s_loadbalancerprops" {
    type = map
    default ={
    subnet = "subnet-lb"
  }
}

variable "k8s_masterprops" {
    type = map
    default ={
    subnet = "subnet-k8s-master"
  }
}

variable "k8s_workerprops" {
    type = map
    default ={
    subnet = "subnet-k8s-worker"
  }
}
