############################################
# Parametro SSM per configurazione CloudWatch Agent (Linux)
############################################

resource "aws_ssm_parameter" "cwagent_config_linux" {
  name        = "/AmazonCloudWatch/linux"
  description = "Configurazione CloudWatch Agent per Linux"
  type        = "String"             # oppure "SecureString" se vuoi cifrare
  tier        = "Standard"           # o "Advanced" se serve >4KB

  value = <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "CWAgent",
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"]
      }
    }
  }
}
EOF

  tags = {
    Application = "CloudWatchAgent"
    OS          = "Linux"
  }
}