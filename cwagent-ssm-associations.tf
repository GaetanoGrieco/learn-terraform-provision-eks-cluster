############################################
# CloudWatch Agent Installation & Configuration
# via SSM Associations (Opzione B)
############################################

# INSTALLA il pacchetto AmazonCloudWatchAgent su tutti i nodi EKS
 resource "aws_ssm_association" "cwagent_install" {
  name = "AWS-ConfigureAWSPackage"

  parameters = {
    action = "Install"                  # deve essere stringa
    name   = "AmazonCloudWatchAgent"    # nome del package
  }

  # Il target sono le EC2 dei node groups EKS
  targets {
    key    = "tag:eks.amazonaws.com/nodegroup"
    values = [
      "node-group-1",
      "node-group-2"
    ]
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
    values = [
      "node-group-1",
      "node-group-2"
    ]
  }

  depends_on = [
    aws_ssm_association.cwagent_install,
    aws_ssm_parameter.cwagent_config_linux
  ]
}