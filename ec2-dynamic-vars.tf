############################################
# Raccogli automaticamente le EC2 dei node groups
############################################

# Node Group 1
data "aws_instances" "ng_one" {
  filter {
    name   = "tag:eks.amazonaws.com/nodegroup"
    values = ["node-group-1"]
  }
}

# Node Group 2
data "aws_instances" "ng_two" {
  filter {
    name   = "tag:eks.amazonaws.com/nodegroup"
    values = ["node-group-2"]
  }
}

locals {
  # Lista unica di tutti gli InstanceIds
  ec2_all_instances = concat(
    data.aws_instances.ng_one.ids,
    data.aws_instances.ng_two.ids
  )
}