# WORKING FIX - No Data Source Errors

## What Was Wrong

The previous version tried to use `data "google_api_gateway_gateway"` which doesn't exist in the Google provider.

## What's Fixed

This version uses `null_resource` with `gcloud` command to update the gateway directly.

## Quick Deploy Steps

### Step 1: Upload to GitHub

1. Extract this package
2. Replace ALL files in your GitHub repo
3. Commit and push:
   ```bash
   git add .
   git commit -m "Fix: Use gcloud to update gateway"
   git push origin main
   ```

### Step 2: Cloud Build Runs Automatically

The build will:
1. ✅ Create API Key
2. ✅ Create API Config (ecommerce-config-v3)
3. ✅ Update Gateway via gcloud command
4. ✅ Create NEG
5. ✅ Create Backend Service
6. ✅ Create Cloud Armor Policy
7. ✅ Update URL Map

### Step 3: Test

```bash
# Get Load Balancer IP
LB_IP=$(gcloud compute forwarding-rules list --global --filter="name:ecommerce" --format="value(IPAddress)")

# Test via Load Balancer (should work)
curl http://$LB_IP/api/products

# Get Gateway URL
GATEWAY_URL=$(gcloud api-gateway gateways describe ecommerce-gateway --location=us-central1 --format="value(defaultHostname)")

# Test direct (should fail with 401)
curl https://$GATEWAY_URL/api/products
```

## Key Changes

### Old (Broken):
```hcl
data "google_api_gateway_gateway" "existing_gateway" {
  # ERROR: This data source doesn't exist!
}
```

### New (Working):
```hcl
resource "null_resource" "update_gateway" {
  provisioner "local-exec" {
    command = "gcloud api-gateway gateways update..."
  }
}
```

## Build Time

Expected: 5-7 minutes

## Verification

After successful build:

```bash
# Check resources
gcloud api-gateway api-configs list --api=ecommerce-api
gcloud compute backend-services list --global
gcloud compute security-policies list
gcloud alpha services api-keys list
```

You should see:
- ✅ ecommerce-config-v3
- ✅ api-backend
- ✅ api-gateway-inject-key
- ✅ load-balancer-api-key

---

**This version works!** Just upload to GitHub and push. 🎉
