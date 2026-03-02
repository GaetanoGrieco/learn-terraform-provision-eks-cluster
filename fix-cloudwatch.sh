#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "  🛠️  FIX CLOUDWATCH - EKS SANDBOX"
echo "========================================"
echo ""

# Step 1: Apply Terraform
echo "➡️  Applying Terraform (nodegroup CloudWatch policy)..."
terraform apply -auto-approve
echo "✔️  Terraform apply completed."
echo ""

# Step 2: Restart DaemonSets (Fluent Bit + CloudWatch Agent)
echo "➡️  Restarting DaemonSets in namespace amazon-cloudwatch..."
kubectl -n amazon-cloudwatch rollout restart daemonset fluent-bit
kubectl -n amazon-cloudwatch rollout restart daemonset cloudwatch-agent

echo "⏳ Waiting for pods to restart..."
sleep 15

echo "➡️  Checking pod status..."
kubectl -n amazon-cloudwatch get pods -o wide
echo ""

# Step 3: Check CloudWatch Agent logs
echo "➡️  Checking CloudWatch Agent logs..."
kubectl -n amazon-cloudwatch logs -l app.kubernetes.io/name=cloudwatch-agent --tail=30 || true
echo ""

# Step 4: Search for AccessDenied errors
echo "➡️  Scanning recent logs for AccessDenied..."
if kubectl -n amazon-cloudwatch logs -l app.kubernetes.io/name=cloudwatch-agent --tail=200 | grep -q "AccessDeniedException"; then
    echo "❌ ERROR: AccessDenied still present!"
    echo "🔍 Check IAM policies or rerun Terraform."
else
    echo "🎉 SUCCESS: No AccessDenied found!"
fi
echo ""

# Step 5: Remind user to check CloudWatch
echo "========================================"
echo "  📊 CHECK CLOUDWATCH CONSOLE"
echo "========================================"
echo "➡️ Logs:  /aws/containerinsights/<cluster>/performance"
echo "➡️ Metrics:  Container Insights → EKS → <cluster>"
echo ""
echo "Done! 🎉"
