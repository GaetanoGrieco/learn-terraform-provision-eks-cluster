############################################
# CloudWatch Agent Installation & Configuration
# via SSM Associations (Opzione B) — CORRETTO
############################################

# INSTALLA il pacchetto AmazonCloudWatchAgent su tutti i nodi EKS
resource "aws_ssm_association" "cwagent_install" {
  name = "AWS-ConfigureAWSPackage"

  parameters = {
    action = "Install"               # deve essere stringa
    name   = "AmazonCloudWatchAgent" # nome del package
  }

  # Target basato sul TAG corretto del nodegroup
  targets {
    key    = "tag:eks.amazonaws.com/nodegroup"
    values = local.node_group_names
  }
}

############################################
# Configura e AVVIA il CloudWatch Agent
# usando il parametro SSM /AmazonCloudWatch/linux
############################################

resource "aws_ssm_association" "cwagent_configure" {
  name = "AmazonCloudWatch-ManageAgent"

  parameters = {
    action                        = "configure"             # deve essere stringa
    mode                          = "ec2"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = "/AmazonCloudWatch/linux"
    optionalRestart               = "yes"
  }

  targets {
    key    = "tag:eks.amazonaws.com/nodegroup"
    values = local.node_group_names
  }

  depends_on = [
    aws_ssm_association.cwagent_install,
    aws_ssm_parameter.cwagent_config_linux
  ]
}