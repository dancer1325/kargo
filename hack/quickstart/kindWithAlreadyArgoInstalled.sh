#!/bin/sh
set -e

# adjust -- based on -- cluster name
CONTEXT="kind-infra"

# cert-manager (Kargo prerequirement)
helm install cert-manager cert-manager \
  --kube-context "$CONTEXT" \
  --repo https://charts.jetstack.io \
  --version 1.19.3 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait

# Kargo (password: admin)
helm install kargo \
  oci://ghcr.io/akuity/kargo-charts/kargo \
  --kube-context "$CONTEXT" \
  --namespace kargo \
  --create-namespace \
  --set api.tls.enabled=false \
  --set 'api.adminAccount.passwordHash=$2a$10$Zrhhie4vLz5ygtVSaif6o.qN36jgs6vjtMBdM6yrU1FOeiAAMMxOm' \
  --set api.adminAccount.tokenSigningKey=iwishtowashmyirishwristwatch \
  --wait

echo ""
echo "Kargo installed. Access the dashboard with:"
echo "  kubectl --context $CONTEXT port-forward -n kargo svc/kargo-api 8443:443"
echo "  Open https://localhost:8443 (user: admin, password: admin)"
