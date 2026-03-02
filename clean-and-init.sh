#!/usr/bin/env bash
set -euo pipefail

echo "🧹 Pulizia Terraform state locale..."
rm -f terraform.tfstate terraform.tfstate.backup || true

echo "🔄 Inizializzo Terraform..."
terraform init -upgrade

echo "🔍 Validazione..."
terraform validate

echo "📦 Pianificazione..."
terraform plan

echo ""
echo "👉 Se il plan sembra corretto, premi INVIO per continuare con apply"
read -r

echo "🚀 Applico configurazione..."
terraform apply -auto-approve

echo ""
echo "🎉 Terraform è pronto!"
echo "Ora puoi eseguire: ./deploy.sh"
