# E-Commerce API Gateway Backend - Terraform Configuration

Production-ready Terraform configuration to secure API Gateway with Cloud Armor and integrate with Google Cloud Load Balancer.

## Overview

This Terraform module creates and configures:
- Serverless Network Endpoint Group (NEG) for API Gateway
- Backend Service for API Gateway traffic management
- Cloud Armor Security Policy with automatic API key injection
- Updated API Gateway configuration with security requirements
- Load Balancer URL Map path matcher for `/api/*` routing

## Architecture

```
Internet
   ↓
Load Balancer (ecommerce-lb)
   ├── /              → Frontend Backend
   └── /api/*         → API Gateway Backend (NEW)
                           ↓
                        Cloud Armor
                        (inject x-api-key)
                           ↓
                        API Gateway
                           ↓
                    ┌──────┴──────┐
                    ↓             ↓
              Product Service  Inventory Service
```

## Prerequisites

1. **Existing Infrastructure**
   - Google Cloud Project with billing enabled
   - API Gateway deployed (`ecommerce-gateway`)
   - Load Balancer configured (`ecommerce-lb`)
   - Cloud Run services running

2. **Required Permissions**
   - `compute.backendServices.*`
   - `compute.networkEndpointGroups.*`
   - `compute.securityPolicies.*`
   - `compute.urlMaps.*`
   - `apigateway.*`
   - `apikeys.*`

3. **Tools**
   - Terraform >= 1.0
   - gcloud CLI configured

## File Structure

```
ecommerce-api-gateway-terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── provider.tf                # Provider configuration
├── deploy.sh                  # Deployment script
├── files/
│   └── openapi.yaml          # OpenAPI specification with security
├── environments/
│   └── dev.tfvars            # Development environment configuration
├── README.md                  # This file
└── .gitignore                 # Git ignore rules
```

## Quick Start

### Step 1: Clone and Navigate

```bash
cd ecommerce-api-gateway-terraform
```

### Step 2: Review Configuration

Edit `environments/dev.tfvars` if needed:

```hcl
project_id = "project-1c4daaee-c7bb-486d-970"
region     = "us-central1"
api_name   = "ecommerce-api"
gateway_name = "ecommerce-gateway"
url_map_name = "ecommerce-lb"
```

### Step 3: Initialize Terraform

```bash
chmod +x deploy.sh
./deploy.sh init
```

### Step 4: Review Changes

```bash
./deploy.sh plan
```

### Step 5: Deploy

```bash
./deploy.sh apply
```

### Step 6: Get API Key

```bash
terraform output -raw api_key
```

**Save this API key securely!**

## Manual Deployment Steps

If you prefer manual commands:

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars

# Get outputs
terraform output
terraform output -raw api_key
```

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_id` | GCP Project ID | `"project-1c4daaee-c7bb-486d-970"` |
| `region` | GCP Region | `"us-central1"` |
| `api_name` | API Gateway API name | `"ecommerce-api"` |
| `gateway_name` | API Gateway name | `"ecommerce-gateway"` |
| `url_map_name` | Load Balancer URL Map | `"ecommerce-lb"` |
| `new_api_config` | New API config version | `"ecommerce-config-v3"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `backend_service_name` | Backend service name | `"api-backend"` |
| `neg_name` | NEG name | `"api-gateway-neg"` |
| `security_policy_name` | Cloud Armor policy name | `"api-gateway-inject-key"` |
| `path_matcher_name` | Path matcher name | `"api-matcher"` |
| `api_path_pattern` | API routing pattern | `"/api/*"` |
| `enable_backend_logs` | Enable logging | `true` |
| `log_sample_rate` | Log sampling rate | `1.0` |

## Outputs

After deployment, you can access:

```bash
# API Key (sensitive)
terraform output -raw api_key

# Configuration summary
terraform output configuration_summary

# Backend service details
terraform output backend_service_details

# All outputs
terraform output
```

## Security Features

### Cloud Armor API Key Injection

The Cloud Armor security policy automatically injects the API key into all requests:

**Result:**
- Direct API Gateway access: `401 UNAUTHENTICATED` (no API key)
- Load Balancer access: `200 OK` (Cloud Armor injects key)

### API Key Restrictions

The API key is restricted to:
- Service: `apigateway.googleapis.com`
- Prevents unauthorized use in other contexts

## Testing

### Test 1: Direct API Gateway Access (Should Fail)

```bash
# Get gateway URL
GATEWAY_URL=$(gcloud api-gateway gateways describe ecommerce-gateway \
  --location=us-central1 \
  --format="value(defaultHostname)")

# Test (should return 401)
curl https://$GATEWAY_URL/api/products
```

**Expected:** `401 UNAUTHENTICATED`

### Test 2: Direct Access with API Key (Should Work)

```bash
API_KEY=$(terraform output -raw api_key)

curl -H "x-api-key: $API_KEY" \
  https://$GATEWAY_URL/api/products
```

**Expected:** `200 OK` with products JSON

### Test 3: Through Load Balancer (Should Work)

```bash
# Get Load Balancer IP
LB_IP=$(gcloud compute forwarding-rules list \
  --global \
  --filter="name:ecommerce" \
  --format="value(IPAddress)")

# Test (should return 200)
curl http://$LB_IP/api/products
```

**Expected:** `200 OK` - Cloud Armor injected the API key!

### Verify Backend Health

```bash
gcloud compute backend-services get-health api-backend --global
```

## Troubleshooting

### Issue: Backend UNHEALTHY

**Solution:**
```bash
# Check backend service
gcloud compute backend-services describe api-backend --global

# Verify NEG
gcloud compute network-endpoint-groups describe api-gateway-neg \
  --region=us-central1
```

### Issue: API Key Not Working

**Solution:**
```bash
# Verify Cloud Armor policy
gcloud compute security-policies describe api-gateway-inject-key

# Check if attached to backend
gcloud compute backend-services describe api-backend --global \
  --format="value(securityPolicy)"
```

### Issue: 404 on API Routes

**Solution:**
```bash
# Check URL Map configuration
gcloud compute url-maps describe ecommerce-lb --global

# Verify path matcher
gcloud compute url-maps describe ecommerce-lb --global \
  --format="value(pathMatchers)"
```

## State Management

This configuration uses **local state** stored in `terraform.tfstate`.

**Important:**
- State file contains sensitive data (API keys)
- Do not commit `terraform.tfstate` to version control
- Backup state file regularly

**For production, consider:**
- Remote state in GCS bucket
- State locking with GCS
- Encrypted state storage

## Cleanup

To destroy all resources:

```bash
./deploy.sh destroy
```

Or manually:

```bash
terraform destroy -var-file=environments/dev.tfvars
```

**Warning:** This will delete:
- API Gateway backend service
- Serverless NEG
- Cloud Armor security policy
- API Key
- URL Map path matcher

## Best Practices

1. **API Key Security**
   - Rotate API keys regularly
   - Store keys in Secret Manager
   - Use different keys per environment

2. **Monitoring**
   - Enable backend logging
   - Monitor Cloud Armor metrics
   - Set up alerts for 4xx/5xx errors

3. **High Availability**
   - Deploy across multiple regions (future)
   - Configure health checks
   - Set appropriate timeout values

4. **Cost Optimization**
   - Adjust log sampling rate in production
   - Review backend service timeout
   - Monitor Cloud Armor pricing

## Support

For issues or questions:
- Review Terraform output errors
- Check GCP Console for resource status
- Verify IAM permissions
- Review Cloud Logging

## Version History

- **v1.0** - Initial release with local state
  - API Gateway backend creation
  - Cloud Armor integration
  - URL Map path matcher

## License

Internal use only

---

**Deployment Checklist:**

- [ ] Review `environments/dev.tfvars`
- [ ] Run `./deploy.sh init`
- [ ] Run `./deploy.sh plan`
- [ ] Run `./deploy.sh apply`
- [ ] Save API key from output
- [ ] Test direct gateway access (should fail)
- [ ] Test Load Balancer access (should work)
- [ ] Verify backend health
- [ ] Document API key location
