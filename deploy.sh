#!/bin/bash
# ============================================================
# Terraform Deployment Script
# ============================================================
# This script deploys the API Gateway backend configuration
#
# Usage:
#   ./deploy.sh [action]
#
# Actions:
#   init     - Initialize Terraform
#   plan     - Plan changes
#   apply    - Apply changes
#   destroy  - Destroy resources
#   output   - Show outputs
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TFVARS_FILE="environments/dev.tfvars"

# ============================================================
# Functions
# ============================================================

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_usage() {
    echo "Usage: $0 [action]"
    echo ""
    echo "Actions:"
    echo "  init     - Initialize Terraform"
    echo "  plan     - Plan changes"
    echo "  apply    - Apply changes"
    echo "  destroy  - Destroy resources"
    echo "  output   - Show outputs"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 plan"
    echo "  $0 apply"
}

# ============================================================
# Main Script
# ============================================================

# Check arguments
if [[ $# -lt 1 ]]; then
    print_error "Missing required action"
    print_usage
    exit 1
fi

ACTION=$1

# Check if tfvars file exists
if [[ ! -f "$TFVARS_FILE" ]]; then
    print_error "Configuration file not found: $TFVARS_FILE"
    exit 1
fi

print_info "Using configuration file: $TFVARS_FILE"
echo ""

# Execute action
case $ACTION in
    init)
        print_info "Initializing Terraform..."
        terraform init
        ;;
        
    plan)
        print_info "Planning Terraform changes..."
        terraform plan -var-file="$TFVARS_FILE"
        ;;
        
    apply)
        print_info "Applying Terraform changes..."
        terraform apply -var-file="$TFVARS_FILE"
        
        if [[ $? -eq 0 ]]; then
            print_info "Deployment successful!"
            echo ""
            print_info "Getting API Key..."
            terraform output -raw api_key
            echo ""
            echo ""
            print_info "Configuration Summary:"
            terraform output configuration_summary
        fi
        ;;
        
    destroy)
        print_warning "This will destroy all resources!"
        echo -n "Type 'yes' to confirm: "
        read confirmation
        if [[ "$confirmation" != "yes" ]]; then
            print_error "Destroy cancelled"
            exit 1
        fi
        
        print_info "Destroying Terraform resources..."
        terraform destroy -var-file="$TFVARS_FILE"
        ;;
        
    output)
        print_info "Terraform Outputs:"
        terraform output
        echo ""
        print_info "To get the API key:"
        echo "  terraform output -raw api_key"
        ;;
        
    *)
        print_error "Invalid action: $ACTION"
        print_usage
        exit 1
        ;;
esac

print_info "Done!"
