#!/bin/bash
set -e

# Base parameters
FRAPPE_BRANCH="version-16"
PYTHON_VERSION="3.11"
NODE_VERSION="18.18.2"

echo "Building custom ERPNext (v16.7.2) + HRMS (version-16) image..."

# Export apps.json to base64
APPS_JSON_BASE64=$(base64 -w 0 apps_v16.json)

# Build command
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=$FRAPPE_BRANCH \
  --build-arg=PYTHON_VERSION=$PYTHON_VERSION \
  --build-arg=NODE_VERSION=$NODE_VERSION \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=erpnext-hrms:latest \
  --file=images/custom/Containerfile .

echo "Build successful! Restart your docker containers to apply."
