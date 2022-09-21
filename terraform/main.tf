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

resource "aws_subnet" "subnet-toptal_k8s_infra" {
    vpc_id = "${aws_vpc.vpc-toptal_k8s_infra.id}"
    cidr_block = "10.0.0.0/24"

    tags = {
        Name = "K8S Cluster Subnet"
    }
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

  // Allow ICMP pings
  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    cidr_blocks = ["0.0.0.0/0"]
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


resource "aws_instance" "k8s_loadbalancers" {

  count = 2

  ami = lookup(var.infrasharedprops, "ami")
  instance_type = lookup(var.infrasharedprops, "itype")
  associate_public_ip_address = lookup(var.infrasharedprops, "publicip")
  key_name = aws_key_pair.generated_keys.key_name

  subnet_id = aws_subnet.subnet-toptal_k8s_infra.id

  vpc_security_group_ids = [
    aws_security_group.sg-toptal_k8s_infra.id
  ]

  root_block_device {
    delete_on_termination = true
    volume_size = 25
    volume_type = "gp2"
  }

  tags = {
    Name ="TT-K8S-LB-${format("%01d", count.index + 1)}"
    Environment = "PRODUCTION"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.sg-toptal_k8s_infra,aws_internet_gateway.gw-toptal_k8s_infra ]
}

resource "aws_instance" "k8s_masters" {

  count = 3

  ami = lookup(var.infrasharedprops, "ami")
  instance_type = lookup(var.infrasharedprops, "itype")
  associate_public_ip_address = lookup(var.infrasharedprops, "publicip")
  key_name = aws_key_pair.generated_keys.key_name

  subnet_id = aws_subnet.subnet-toptal_k8s_infra.id

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

  subnet_id = aws_subnet.subnet-toptal_k8s_infra.id

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


