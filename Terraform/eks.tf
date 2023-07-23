data "aws_availability_zones" "azs" {}

data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks]
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

##################### Create VPC module ##############################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr_block
  private_subnets      = var.private_subnet_cidr_block
  public_subnets       = var.public_subnet_cidr_block
  azs                  = slice(data.aws_availability_zones.azs.names, 0, 3)
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
     "Terraform" = "true"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

###################### Create EKS module #######################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"
  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  enable_irsa                    = true
  create_cloudwatch_log_group    = false
  tags = {
    environment = var.env_perfix
  }

  eks_managed_node_groups = {
    one = {
      name = var.node_name

      instance_types = var.node_type

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

######################################################

