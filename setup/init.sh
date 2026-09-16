#!/bin/bash
set -e -o pipefail

echo "Fetching IAM ARN..."
userarn=$(aws iam get-user --user-name github-action-user --query "User.Arn" --output text 2>/dev/null || aws sts get-caller-identity --query "Arn" --output text)

echo "Using IAM ARN: ${userarn}"

# Download tool for manipulating aws-auth
echo "Downloading tool..."
curl -X GET -L https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.2/aws-iam-authenticator_0.6.2_linux_amd64 -o aws-iam-authenticator
chmod +x aws-iam-authenticator

echo "Updating permissions"
./aws-iam-authenticator add user --userarn="${userarn}" --username=github-action-role --groups=system:masters --kubeconfig="$HOME"/.kube/config --prompt=false || true

echo "Cleaning up"
rm -f aws-iam-authenticator
echo "Done!"