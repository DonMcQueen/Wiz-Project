data "aws_instance" "MongoDBVMv2" {
  instance_id = "i-01a73910944f478be"
}

data "aws_instance" "BastionHost" {
  instance_id = "i-0821647faa92a23ff"
}

data "aws_vpc" "default-vpc" {
  id = "vpc-ff5b1b85"
}

data "aws_subnet" "WizPublicSubnet" {
  id = "subnet-0b49b011820a4466d"
}

data "aws_subnet" "WizPrivateSubnetA" {
  id = "subnet-05b4848fa221e0d86"
}

data "aws_subnet" "WizPrivateSubnetB" {
  id = "subnet-0e181cebc851c5f86"
}

data "aws_route_table" "WizPublicRT" {
  subnet_id = data.aws_subnet.WizPublicSubnet.id

  filter {
    name   = "tag:Name"
    values = ["WizPublicRT"]
  }
}

data "aws_route_table" "WizPrivateRT" {
  subnet_id = data.aws_subnet.WizPrivateSubnetA.id

  filter {
    name   = "tag:Name"
    values = ["WizPrivateRT"]
  }
}

data "aws_internet_gateway" "default-internet-gateway" {
  filter {
    name   = "tag:Name"
    values = ["default-internet-gateway"]
  }
  internet_gateway_id = "igw-e3c07798"
}

data "aws_nat_gateway" "newnatgw" {
  subnet_id = data.aws_subnet.WizPublicSubnet.id
}

data "aws_network_acls" "WizNACL" {
  vpc_id = "vpc-ff5b1b85"

  tags = {
    Name = "WizNACL"
  }
}

data "aws_security_groups" "eksctl-wiz-cluster-plz-work-this-time-cluster-ClusterSharedNodeSecurityGroup-Q0K2AZRB1RM2" {
  tags = {
    Name = "eksctl-wiz-cluster-plz-work-this-time-cluster-ClusterSharedNodeSecurityGroup-Q0K2AZRB1RM2"
  }
}

data "aws_security_groups" "eks-cluster-sg-wiz-cluster-plz-work-this-time-2144064441" {
  tags = {
    Name = "eks-cluster-sg-wiz-cluster-plz-work-this-time-2144064441"
  }
}

data "aws_security_groups" "eksctl-wiz-cluster-plz-work-this-time-cluster-ControlPlaneSecurityGroup-7J9QCEYKB3O1" {
  tags = {
    Name = "eksctl-wiz-cluster-plz-work-this-time-cluster-ControlPlaneSecurityGroup-7J9QCEYKB3O1"
  }
}

data "aws_security_groups" "eksctl-wiz-cluster-plz-work-this-time-nodegroup-WizNodeGroup-SG-68W700JSOGX2" {
  tags = {
    Name = "eksctl-wiz-cluster-plz-work-this-time-nodegroup-WizNodeGroup-SG-68W700JSOGX2"
  }
}

data "aws_security_groups" "MongoDBSecurityGroup" {
  tags = {
    Name = "MongoDBSecurityGroup"
  }
}

data "aws_security_groups" "bastion-sg" {
  tags = {
    Name = "bastion-sg"
  }
}

data "aws_security_groups" "k8s-elb-a629a856a8de844df825ff4ea35e38a9" {
  tags = {
    Name = "k8s-elb-a629a856a8de844df825ff4ea35e38a9"
  }
}

data "aws_s3_bucket" "wizdemobucketpublic" {
  bucket = "wizdemobucketpublic"
}