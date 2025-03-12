#!/bin/bash

set -e

# Define Variables
CLUSTER_NAME="travel-blog-cluster"
REGION="us-east-1"
NODE_TYPE="t3.medium"
NODE_COUNT=1

# Create EKS Cluster
echo "🚀 Creating EKS Cluster..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name "$CLUSTER_NAME-group" \
  --node-type $NODE_TYPE \
  --nodes $NODE_COUNT \
  --nodes-min 1 \
  --nodes-max 2 \
  --managed

# Associate OIDC Provider (Required for IAM Roles for Service Accounts)
echo "🔒 Associating OIDC Provider..."
eksctl utils associate-iam-oidc-provider --region $REGION --cluster $CLUSTER_NAME --approve

# Install ArgoCD
echo "📥 Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Patch ArgoCD to Use NodePort
echo "🌐 Exposing ArgoCD using NodePort..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Wait for ArgoCD Pods to be Ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment argocd-server -n argocd --timeout=300s

# Get NodePort
NODE_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

if [ -z "$NODE_IP" ]; then
  NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi

ARGOCD_URL="https://$NODE_IP:$NODE_PORT"

# Get Initial Admin Password
echo "🔑 Getting ArgoCD admin password..."
sleep 10
PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)

# Output ArgoCD URL and Password
echo "✅ ArgoCD Installation Complete!"
echo "🌍 ArgoCD URL: $ARGOCD_URL"
echo "🔑 ArgoCD Admin Password: $PASSWORD"
