// Package tests provides integration tests for the Azure VNET Terraform module.
//
// Prerequisites:
//   - Go >= 1.21
//   - Terraform >= 1.5.0
//   - An Azure subscription with the following env vars set:
//       ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
//
// Run: go test -v -timeout 30m ./...
package tests

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	armnetwork "github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/network/armnetwork/v5"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func requiredEnv(t *testing.T, key string) string {
	t.Helper()
	val := os.Getenv(key)
	if val == "" {
		t.Fatalf("required environment variable %q is not set", key)
	}
	return val
}

// ---------------------------------------------------------------------------
// Unit-style test — validates module structure without deploying
// ---------------------------------------------------------------------------

// TestVnetModuleValidate runs terraform init + validate against the module
// using a local (no-backend) configuration to catch syntax / type errors.
func TestVnetModuleValidate(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vnet",
		// -backend=false so we don't need real credentials
		InitArgs: []string{"-backend=false"},
		// Disable coloured output for cleaner logs
		NoColor: true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// ---------------------------------------------------------------------------
// Integration test — deploys a minimal VNET and validates real outputs
// ---------------------------------------------------------------------------

// TestVnetModuleIntegration deploys the VNET module to a real Azure subscription,
// asserts the expected resources exist, then destroys everything.
//
// To skip this test in CI, set the env var SKIP_INTEGRATION_TESTS=true.
func TestVnetModuleIntegration(t *testing.T) {
	if os.Getenv("SKIP_INTEGRATION_TESTS") == "true" {
		t.Skip("Skipping integration test (SKIP_INTEGRATION_TESTS=true)")
	}
	t.Parallel()

	subscriptionID := requiredEnv(t, "ARM_SUBSCRIPTION_ID")

	// Unique suffix to avoid naming collisions when tests run in parallel
	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-terratest-%s", uniqueID)
	vnetName          := fmt.Sprintf("vnet-terratest-%s", uniqueID)
	location          := "eastus"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vnet",
		NoColor:      true,

		Vars: map[string]interface{}{
			"create_resource_group": true,
			"resource_group_name":   resourceGroupName,
			"location":              location,
			"vnet_name":             vnetName,
			"vnet_address_space":    []string{"10.99.0.0/16"},
			"subnets": map[string]interface{}{
				"snet-test-app": map[string]interface{}{
					"address_prefixes":  []string{"10.99.0.0/24"},
					"service_endpoints": []string{"Microsoft.Storage"},
				},
				"snet-test-data": map[string]interface{}{
					"address_prefixes": []string{"10.99.1.0/24"},
				},
			},
			"network_security_groups": map[string]interface{}{
				"nsg-test-app": map[string]interface{}{
					"security_rules": []map[string]interface{}{
						{
							"name":                       "allow-ssh",
							"priority":                   100,
							"direction":                  "Inbound",
							"access":                     "Allow",
							"protocol":                   "Tcp",
							"source_port_range":          "*",
							"destination_port_range":     "22",
							"source_address_prefix":      "VirtualNetwork",
							"destination_address_prefix": "*",
						},
					},
				},
			},
			"nsg_subnet_associations": map[string]interface{}{
				"snet-test-app": "nsg-test-app",
			},
			"tags": map[string]interface{}{
				"environment": "terratest",
				"project":     "myapp",
				"owner":       "ci",
				"cost_center": "CC-0000",
			},
		},
	})

	// Ensure cleanup always runs
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// ── Assertions ────────────────────────────────────────────────────────

	// 1. Outputs must be non-empty
	outputVnetID           := terraform.Output(t, terraformOptions, "vnet_id")
	outputRGName           := terraform.Output(t, terraformOptions, "resource_group_name")
	outputSubnetIDsRaw     := terraform.OutputMap(t, terraformOptions, "subnet_ids")

	assert.NotEmpty(t, outputVnetID, "vnet_id output must not be empty")
	assert.Equal(t, resourceGroupName, outputRGName)
	assert.Len(t, outputSubnetIDsRaw, 2, "expected 2 subnet IDs")

	// 2. VNET really exists in Azure (via SDK)
	exists := azure.VirtualNetworkExists(t, vnetName, resourceGroupName, subscriptionID)
	assert.True(t, exists, "VNET should exist in Azure after apply")

	// 3. Verify correct address space via Azure SDK
	vnet := fetchVnet(t, subscriptionID, resourceGroupName, vnetName)
	require.NotNil(t, vnet.Properties)
	require.NotNil(t, vnet.Properties.AddressSpace)
	require.Len(t, vnet.Properties.AddressSpace.AddressPrefixes, 1)
	assert.Equal(t, "10.99.0.0/16", *vnet.Properties.AddressSpace.AddressPrefixes[0])

	// 4. Both subnets exist
	assert.Contains(t, outputSubnetIDsRaw, "snet-test-app")
	assert.Contains(t, outputSubnetIDsRaw, "snet-test-data")

	// 5. NSG output contains expected key
	nsgIDs := terraform.OutputMap(t, terraformOptions, "nsg_ids")
	assert.Contains(t, nsgIDs, "nsg-test-app")
}

// ---------------------------------------------------------------------------
// Negative / validation test — ensure bad CIDR is rejected
// ---------------------------------------------------------------------------

func TestVnetModuleInvalidCIDRFails(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vnet",
		NoColor:      true,
		InitArgs:     []string{"-backend=false"},

		Vars: map[string]interface{}{
			"create_resource_group": true,
			"resource_group_name":   "rg-invalid-test",
			"location":              "eastus",
			"vnet_name":             "vnet-invalid",
			"vnet_address_space":    []string{}, // empty — should fail validation
		},
	}

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)
	assert.Error(t, err, "plan should fail when vnet_address_space is empty")
}

// ---------------------------------------------------------------------------
// SDK helper
// ---------------------------------------------------------------------------

func fetchVnet(t *testing.T, subscriptionID, rgName, vnetName string) armnetwork.VirtualNetwork {
	t.Helper()

	cred, err := azidentity.NewDefaultAzureCredential(nil)
	require.NoError(t, err)

	client, err := armnetwork.NewVirtualNetworksClient(subscriptionID, cred, nil)
	require.NoError(t, err)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	resp, err := client.Get(ctx, rgName, vnetName, nil)
	require.NoError(t, err)

	return resp.VirtualNetwork
}
