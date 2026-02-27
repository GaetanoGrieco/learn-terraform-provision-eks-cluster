#!/usr/bin/env bash
set -euo pipefail

# ==============================
# Config
# ==============================
PROFILE="${AWS_PROFILE:-}"
REGION="${AWS_REGION:-us-east-1}"

# Attesa per propagazione IAM/Pod Identity (secondi)
IAM_PROP_SECONDS=60

# ==============================
# Helpers
# ==============================
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

require_bin() {
  local b="$1"
  command -v "$b" >/dev/null 2>&1 || { red "❌ Comando richiesto non trovato: $b"; exit 1; }
}

# ==============================
# Pre-flight checks
# ==============================
require_bin aws
require_bin terraform
require_bin kubectl
require_bin jq

yellow "🔐 Verifica credenziali AWS..."
if ! aws sts get-caller-identity --output json >/dev/null 2>&1; then
  red "❌ Credenziali AWS non valide o scadute."
  echo "Se usi SSO:"
  echo "  aws sso login --profile <tuo-profilo>"
  echo "  export AWS_PROFILE=<tuo-profilo>"
  echo "Oppure esporta le variabili d'ambiente con chiavi temporanee (AWS_ACCESS_KEY_ID/SECRET/SESSION_TOKEN)."
  exit 1
fi
acct_json="$(aws sts get-caller-identity --output json)"
acct_id=$(echo "$acct_json" | jq -r '.Account')
yellow "ℹ️  Account: $acct_id | Regione: ${REGION}"
green "✅ Credenziali OK"

# ==============================
# Terraform init/plan/apply
# ==============================
yellow "🧰 Terraform init/plan/apply..."
terraform fmt -recursive
terraform init -upgrade
terraform validate
terraform apply -auto-approve

# ==============================
# Recupero nome cluster da output TF
# ==============================
CLUSTER_NAME="$(terraform output -raw cluster_name)"
if [[ -z "${CLUSTER_NAME}" ]]; then
  red "❌ Impossibile leggere l'output 'cluster_name' da Terraform."
  exit 1
fi
green "✅ Cluster: ${CLUSTER_NAME}"

# ==============================
# Attesa cluster ACTIVE (safety)
# ==============================
yellow "⏳ Attendo che EKS sia ACTIVE..."
aws eks wait cluster-active --region "${REGION}" --name "${CLUSTER_NAME}"
green "✅ Cluster ACTIVE"

# ==============================
# kubeconfig update
# ==============================
yellow "📁 Aggiorno kubeconfig..."
aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}" >/dev/null
kubectl cluster-info >/dev/null 2>&1 || { red "❌ kubectl non riesce a parlare con l'API del cluster."; exit 1; }
green "✅ kubeconfig aggiornato"

# ==============================
# Check add-on EKS
# ==============================
yellow "🔎 Verifico add-on EKS..."
echo -n " - eks-pod-identity-agent: "
aws eks describe-addon --region "${REGION}" --cluster-name "${CLUSTER_NAME}" \
  --addon-name eks-pod-identity-agent --query "addon.status" --output text || true
echo -n " - amazon-cloudwatch-observability: "
aws eks describe-addon --region "${REGION}" --cluster-name "${CLUSTER_NAME}" \
  --addon-name amazon-cloudwatch-observability --query "addon.status" --output text || true

# ==============================
# Attesa propagazione IAM
# ==============================
yellow "⏳ Attendo ${IAM_PROP_SECONDS}s per propagazione IAM/Pod Identity..."
sleep "${IAM_PROP_SECONDS}"

# ==============================
# Verifica Pod Identity association
# ==============================
yellow "🔎 Verifico Pod Identity association (amazon-cloudwatch/cloudwatch-agent)..."
ASSOC_JSON="$(aws eks list-pod-identity-associations --region "${REGION}" --cluster-name "${CLUSTER_NAME}" --output json)"
ASSOC_MATCH=$(echo "${ASSOC_JSON}" | jq -r --arg ns "amazon-cloudwatch" --arg sa "cloudwatch-agent" '.associations[]? | select(.namespace==$ns and .serviceAccount==$sa) | .roleArn // empty')

if [[ -z "${ASSOC_MATCH}" ]]; then
  yellow "ℹ️ Nessuna associazione con roleArn trovata; provo a riallineare via Terraform..."
  terraform apply -auto-approve
  # Rilettura
  ASSOC_JSON="$(aws eks list-pod-identity-associations --region "${REGION}" --cluster-name "${CLUSTER_NAME}" --output json)"
  ASSOC_MATCH=$(echo "${ASSOC_JSON}" | jq -r --arg ns "amazon-cloudwatch" --arg sa "cloudwatch-agent" '.associations[]? | select(.namespace==$ns and .serviceAccount==$sa) | .roleArn // empty')
fi

if [[ -z "${ASSOC_MATCH}" ]]; then
  red "❌ L'associazione Pod Identity non risulta con roleArn."
  echo "Controlla che in Terraform:"
  echo " - aws_iam_role.cw_observability abbia nella trust policy: [\"sts:AssumeRole\",\"sts:TagSession\"]"
  echo " - aws_eks_pod_identity_association.cw_observability usi role_arn = aws_iam_role.cw_observability.arn"
  exit 1
fi
green "✅ Pod Identity association OK (roleArn: ${ASSOC_MATCH})"

# ==============================
# Riavvia CloudWatch Agent e health-check
# ==============================
yellow "🔁 Riavvio CloudWatch Agent..."
kubectl rollout restart daemonset cloudwatch-agent -n amazon-cloudwatch >/dev/null || true
sleep 10
yellow "📜 Ultime righe dei log CloudWatch Agent:"
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent -c otc-container --tail=50 || true

# ==============================
# Controllo log group su CloudWatch (performance)
# ==============================
yellow "📄 Verifico log group Container Insights (performance)..."
aws logs describe-log-groups \
  --region "${REGION}" \
  --log-group-name-prefix "/aws/containerinsights/${CLUSTER_NAME}/performance" \
  --output json | jq '.logGroups[]?.logGroupName' || true

green "🎉 Deploy completato!"
echo "Cluster: ${CLUSTER_NAME}"
echo "Suggerimenti:"
echo " - kubectl get nodes"
echo " - CloudWatch → Metrics → Container Insights → EKS → ${CLUSTER_NAME}"
echo " - CloudWatch → Logs → /aws/containerinsights/${CLUSTER_NAME}/performance"