#!/usr/bin/env bash
set -euo pipefail

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

yellow "🧨 Terraform destroy..."
if ! terraform destroy -auto-approve; then
  red "⚠️ Destroy incompleto. Se blocca su VPC/IGW/NAT/ENI:"
  echo " - verifica ed elimina eventuali ENI o LB orfani nel VPC"
  echo " - stacca e cancella IGW se necessario"
  echo " - ripeti 'terraform destroy'"
  exit 1
fi

green "✅ Distrutto"