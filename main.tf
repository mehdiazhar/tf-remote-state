data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "mehdi-vpc-tfstate"
    key            = "env:/${terraform.workspace}/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "mehdi-lock"
  }
}

# output "vpc_id" {
#   value = module.vpc.vpc_out.public_subnets_ids
# }

module "alb" {
  source        = "./modules/alb"
  vpc_id        = data.terraform_remote_state.vpc.outputs.root_vpc.vpc_id
  public_subnet = data.terraform_remote_state.vpc.outputs.root_vpc.public_subnets_ids
}

module "asg" {
  source           = "./modules/asg"
  vpc_id           = data.terraform_remote_state.vpc.outputs.root_vpc.vpc_id
  private_subnet   = data.terraform_remote_state.vpc.outputs.root_vpc.private_subnets_ids
  key_name         = var.key_name
  instance_type    = var.instance_type
  alb_sg           = module.alb.alb_out.alb_sg
  alb_tg           = module.alb.alb_out.alb_tg
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
  clb_dns          = module.elb.clb_dns
}

module "elb" {
  source         = "./modules/elb"
  vpc_id         = data.terraform_remote_state.vpc.outputs.root_vpc.vpc_id
  private_subnet = data.terraform_remote_state.vpc.outputs.root_vpc.private_subnets_ids
  asgsg          = module.asg.asgsg
  sql_id         = module.sqldb.sql_id
}

module "sqldb" {
  source         = "./modules/sqldb"
  sqldbinstance  = var.sqldbinstance
  instance_type  = var.instance_type
  key_name       = var.key_name
  vpc_id         = data.terraform_remote_state.vpc.outputs.root_vpc.vpc_id
  private_subnet = data.terraform_remote_state.vpc.outputs.root_vpc.private_subnets_ids
  clb_sg         = module.elb.clb_sg
}