# Makefile for AWS Static Website Terraform Module
# Common operations for managing the Terraform infrastructure

.PHONY: help init plan apply destroy validate fmt clean test

# Default target
help:
	@echo "Available commands:"
	@echo "  init      - Initialize Terraform"
	@echo "  plan      - Plan Terraform changes"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy Terraform infrastructure"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform code"
	@echo "  clean     - Clean up Terraform files"
	@echo "  test      - Run validation and formatting"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init

# Plan Terraform changes
plan:
	@echo "Planning Terraform changes..."
	terraform plan

# Apply Terraform changes
apply:
	@echo "Applying Terraform changes..."
	terraform apply

# Apply Terraform changes with auto-approve
apply-auto:
	@echo "Applying Terraform changes (auto-approve)..."
	terraform apply -auto-approve

# Destroy Terraform infrastructure
destroy:
	@echo "Destroying Terraform infrastructure..."
	terraform destroy

# Destroy Terraform infrastructure with auto-approve
destroy-auto:
	@echo "Destroying Terraform infrastructure (auto-approve)..."
	terraform destroy -auto-approve

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	terraform validate

# Format Terraform code
fmt:
	@echo "Formatting Terraform code..."
	terraform fmt -recursive

# Clean up Terraform files
clean:
	@echo "Cleaning up Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
	rm -f *.tfplan

# Run all validation and formatting
test: validate fmt
	@echo "All checks passed!"

# Show Terraform version
version:
	@echo "Terraform version:"
	terraform version

# Show Terraform state
state:
	@echo "Terraform state:"
	terraform show

# List Terraform resources
list:
	@echo "Terraform resources:"
	terraform state list

# Refresh Terraform state
refresh:
	@echo "Refreshing Terraform state..."
	terraform refresh

# Output Terraform outputs
output:
	@echo "Terraform outputs:"
	terraform output

# Workspace operations
workspace-list:
	@echo "Available workspaces:"
	terraform workspace list

workspace-new:
	@echo "Creating new workspace..."
	@read -p "Enter workspace name: " workspace; \
	terraform workspace new $$workspace

workspace-select:
	@echo "Selecting workspace..."
	@read -p "Enter workspace name: " workspace; \
	terraform workspace select $$workspace

# Security scanning (if tflint is available)
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		echo "Running TFLint..."; \
		tflint; \
	else \
		echo "TFLint not found. Install with: go install github.com/terraform-linters/tflint/cmd/tflint@latest"; \
	fi

# Security scanning (if terrascan is available)
security-scan:
	@if command -v terrascan >/dev/null 2>&1; then \
		echo "Running Terrascan security scan..."; \
		terrascan scan; \
	else \
		echo "Terrascan not found. Install with: curl -L \"\$$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -m 1 \"https://.*_Linux_x86_64.tar.gz\")\" | tar -xz terrascan && sudo mv terrascan /usr/local/bin/"; \
	fi

# Full validation pipeline
full-validate: validate fmt lint security-scan
	@echo "Full validation completed!"

# Example deployment commands
deploy-basic:
	@echo "Deploying basic example..."
	cd examples/basic && terraform init && terraform apply -auto-approve

deploy-advanced:
	@echo "Deploying advanced example..."
	cd examples/advanced && terraform init && terraform apply -auto-approve

deploy-existing-zone:
	@echo "Deploying existing hosted zone example..."
	cd examples/existing-hosted-zone && terraform init && terraform apply -auto-approve

# Clean up examples
clean-examples:
	@echo "Cleaning up examples..."
	cd examples/basic && terraform destroy -auto-approve || true
	cd examples/advanced && terraform destroy -auto-approve || true
	cd examples/existing-hosted-zone && terraform destroy -auto-approve || true 