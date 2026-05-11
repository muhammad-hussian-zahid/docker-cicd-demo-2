#!/bin/bash
set -e

IMAGE_NAME=$1
REPORT_FORMAT=${2:-table}
SEVERITY=${3:-HIGH,CRITICAL}

if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image-name> [report-format] [severity]"
    exit 1
fi

echo "Running security scan on image: $IMAGE_NAME"

# Install Trivy if not present
if ! command -v trivy &> /dev/null; then
    echo "Installing Trivy..."
    sudo apt-get update
    sudo apt-get install wget apt-transport-https gnupg lsb-release -y
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install trivy -y
fi

# Create reports directory
mkdir -p reports

# Run vulnerability scan
echo "Scanning for vulnerabilities..."
trivy image --format $REPORT_FORMAT --severity $SEVERITY --output reports/security-report.txt $IMAGE_NAME

# Generate JSON report for CI/CD integration
trivy image --format json --severity $SEVERITY --output reports/security-report.json $IMAGE_NAME

# Check if critical vulnerabilities found
CRITICAL_COUNT=$(trivy image --format json --severity CRITICAL $IMAGE_NAME | jq '.Results[]?.Vulnerabilities // [] | length' | awk '{sum+=$1} END {print sum+0}')

echo "Critical vulnerabilities found: $CRITICAL_COUNT"

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "WARNING: Critical vulnerabilities detected!"
    echo "Review the security report before proceeding with deployment."
    # Uncomment the next line to fail the build on critical vulnerabilities
    # exit 1
fi

echo "Security scan completed. Reports saved in reports/ directory."
