variable "infrasharedprops" {
  type = map
  default = {
    region = "us-east-1"
    vpc = "vpc-toptal_k8s_infra"
    ami = "ami-052efd3df9dad4825"
    itype = "t2.micro"
    publicip = true
    secgroupname = "tt-k8s-cluster-security-group"
    keypair_name = "tt-k8s-cluster-keys"
    }
}

variable "k8s_masterprops" {
    type = map
    default ={
    subnet = "subnet-k8s-master"
    itype = "t2.medium"
  }
}

variable "k8s_workerprops" {
    type = map
    default ={
    subnet = "subnet-k8s-worker"
  }
}
