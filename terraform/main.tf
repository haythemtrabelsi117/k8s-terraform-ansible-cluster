resource "tls_private_key" "key-toptal_k8s_infra" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_keys" {
  key_name   = lookup(var.infrasharedprops, "keypair_name")
  public_key = tls_private_key.key-toptal_k8s_infra.public_key_openssh
}


resource "aws_vpc" "vpc-toptal_k8s_infra" {
  cidr_block = "10.0.0.0/16"
  tags = {
  	Name = "K8S Cluster VPC"
  }
}

resource "aws_subnet" "subnet-toptal_k8s_infra-us-east-a" {
    vpc_id = "${aws_vpc.vpc-toptal_k8s_infra.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "K8S Cluster US East A Subnet"
    }
}

resource "aws_subnet" "subnet-toptal_k8s_infra-us-east-c" {
    vpc_id = "${aws_vpc.vpc-toptal_k8s_infra.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1c"

    tags = {
        Name = "K8S Cluster US East C Subnet"
    }
}

locals {
  subs =  concat( [aws_subnet.subnet-toptal_k8s_infra-us-east-a.id], [aws_subnet.subnet-toptal_k8s_infra-us-east-c.id] )
  security_groups = concat([aws_security_group.sg-toptal_k8s_lb.id])
}

resource "aws_internet_gateway" "gw-toptal_k8s_infra" {
  vpc_id = "${aws_vpc.vpc-toptal_k8s_infra.id}"

  tags = {
    Name = "K8S Cluster Internet GW/Router"
  }
}

resource "aws_default_route_table" "rt-toptal_k8s_infa" {
  //vpc_id = "${aws_vpc.vpc-toptal_k8s_infra.id}"
  default_route_table_id = "${aws_vpc.vpc-toptal_k8s_infra.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-toptal_k8s_infra.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw-toptal_k8s_infra.id
  }

  tags = {
    Name = "K8S Cluster Routing Table"
  }

}

resource "aws_lb_target_group" "albtg-toptal_k8s_infra" {
    name     = "k8s-masters"
    port     = 6443
    protocol = "TCP"
    vpc_id   = aws_vpc.vpc-toptal_k8s_infra.id
}

resource "aws_lb_target_group_attachment" "tg_attachment-toptal_k8s_infra" {
    count = length(aws_instance.k8s_masters)
    target_group_arn = aws_lb_target_group.albtg-toptal_k8s_infra.arn
    target_id = aws_instance.k8s_masters[count.index].id
    port             = 6443
}

resource "aws_lb" "lb-toptal_k8s_infra" {
    name               = "k8s-loadbalancer"
    internal           = false
    load_balancer_type = "network" 
    subnets            = [aws_subnet.subnet-toptal_k8s_infra-us-east-a.id, aws_subnet.subnet-toptal_k8s_infra-us-east-c.id]
    enable_cross_zone_load_balancing = "true"
    tags = {
         Environment = "Production"
         Role        = "K8S Cluster Control Plane Loadbalancer"
    }
}

resource "aws_lb_listener" "lb-tcp_listener" {
   load_balancer_arn    = aws_lb.lb-toptal_k8s_infra.id
   port                 = "6443"
   protocol             = "TCP"
   default_action {
    target_group_arn = aws_lb_target_group.albtg-toptal_k8s_infra.id
    type             = "forward"
  }
}

resource "aws_security_group" "sg-toptal_k8s_lb" {
  //name = "K8S LB security group"
  name = "Loadbalancer security group"
  description = "Loadbalancer security group"
  vpc_id = aws_vpc.vpc-toptal_k8s_infra.id

  // Allow Kubernetes API in from workers
  ingress {
    from_port = 6443
    protocol = "tcp"
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow Kubernetes API out to masters
  egress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
  }
	

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "sg-toptal_k8s_infra" {
  name = lookup(var.infrasharedprops, "secgroupname")
  description = lookup(var.infrasharedprops, "secgroupname")
  vpc_id = aws_vpc.vpc-toptal_k8s_infra.id

  // Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow Kubernetes API access from all nodes (apply to masters)
  ingress {
    from_port = 6443
    protocol = "tcp"
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow etcd access from control nodes only (apply to masters)
  ingress {
    from_port = 2379
    protocol = "tcp"
    to_port = 2380
    cidr_blocks = ["10.0.0.0/16"]
  }

  // Allow kubelet API access from control nodes only (apply to workers + masters)
  ingress {
    from_port = 10250
    protocol = "tcp"
    to_port = 10250
    cidr_blocks = ["10.0.0.0/16"]
  }

  // Allow NodePort Services access from all nodes (apply to workers)
  ingress {
    from_port = 30000
    protocol = "tcp"
    to_port = 32767
    cidr_blocks = ["10.0.0.0/16"]
  }

  // Allow weave networking
  ingress {
    from_port = 6783
    protocol = "tcp"
    to_port = 6783
    cidr_blocks = ["10.0.0.0/16"]
  }

  // Allow weave networking
  ingress {
    from_port = 6783
    protocol = "udp"
    to_port = 6784
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "k8s_masters" {

  count = 3

  ami = lookup(var.infrasharedprops, "ami")
  instance_type = lookup(var.k8s_masterprops, "itype")
  associate_public_ip_address = lookup(var.infrasharedprops, "publicip")
  key_name = aws_key_pair.generated_keys.key_name

  subnet_id = element(local.subs, count.index)

  vpc_security_group_ids = [
    aws_security_group.sg-toptal_k8s_infra.id
  ]

  root_block_device {
    delete_on_termination = true
    volume_size = 25
    volume_type = "gp2"
  }

  tags = {
    Name ="TT-K8S-MASTER-${format("%01d", count.index + 1)}"
    Environment = "PRODUCTION"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.sg-toptal_k8s_infra,aws_internet_gateway.gw-toptal_k8s_infra ]
}

resource "aws_instance" "k8s_workers" {

  count = 3

  ami = lookup(var.infrasharedprops, "ami")
  instance_type = lookup(var.infrasharedprops, "itype")
  associate_public_ip_address = lookup(var.infrasharedprops, "publicip")
  key_name = aws_key_pair.generated_keys.key_name

  subnet_id = element(local.subs, count.index)

  vpc_security_group_ids = [
    aws_security_group.sg-toptal_k8s_infra.id
  ]

  root_block_device {
    delete_on_termination = true
    volume_size = 25
    volume_type = "gp2"
  }

  tags = {
    Name ="TT-K8S-WORKER-${format("%01d", count.index + 1)}"
    Environment = "PRODUCTION"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.sg-toptal_k8s_infra,aws_internet_gateway.gw-toptal_k8s_infra ]
}
