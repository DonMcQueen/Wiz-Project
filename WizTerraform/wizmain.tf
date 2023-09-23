terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role_policy_attachment" "wiz-AmazonEKSClusterPolicy-terraform" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.wiz-iam-role-terraform.name
}

resource "aws_iam_role" "wiz-iam-role-terraform" {
  name               = "wiz-iam-role-terraform"
  assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Effect = "Allow", 
            "Principal" : { 
                "Service": "eks.amazonaws.com"
            }, 
            "Action": "sts:AssumeRole"
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "wiz-AmazonEKSVPCResourceController-terraform" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.wiz-iam-role-terraform.name
}

resource "aws_eks_cluster" "wiz-cluster" {
  name     = "wiz-cluster"
  role_arn = aws_iam_role.wiz-iam-role-terraform.arn

  vpc_config {
    subnet_ids = [data.aws_subnet.WizPublicSubnet.id, data.aws_subnet.WizPrivateSubnetA.id, data.aws_subnet.WizPrivateSubnetB.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.wiz-AmazonEKSClusterPolicy-terraform,
    aws_iam_role_policy_attachment.wiz-AmazonEKSVPCResourceController-terraform,
  ]
}