#!/bin/bash

# AWS Static Website Module Validation Script
# This script validates the Terraform module configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --all                   Run all validations"
    echo "  -t, --terraform             Run Terraform validation only"
    echo "  -f, --format                Run Terraform formatting only"
    echo "  -l, --lint                  Run TFLint validation (if available)"
    echo "  -s, --security              Run security scanning (if available)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -a"
    echo "  $0 -t -f"
    echo "  $0 --lint --security"
}

# Default values
RUN_TERRAFORM=false
RUN_FORMAT=false
RUN_LINT=false
RUN_SECURITY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            RUN_TERRAFORM=true
            RUN_FORMAT=true
            RUN_LINT=true
            RUN_SECURITY=true
            shift
            ;;
        -t|--terraform)
            RUN_TERRAFORM=true
            shift
            ;;
        -f|--format)
            RUN_FORMAT=true
            shift
            ;;
        -l|--lint)
            RUN_LINT=true
            shift
            ;;
        -s|--security)
            RUN_SECURITY=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# If no specific validation is requested, run all
if [[ "$RUN_TERRAFORM" == false && "$RUN_FORMAT" == false && "$RUN_LINT" == false && "$RUN_SECURITY" == false ]]; then
    RUN_TERRAFORM=true
    RUN_FORMAT=true
    RUN_LINT=true
    RUN_SECURITY=true
fi

print_status "Starting module validation..."

# Check if we're in the right directory
if [[ ! -f "main.tf" ]] || [[ ! -f "variables.tf" ]] || [[ ! -f "outputs.tf" ]]; then
    print_error "This script must be run from the module root directory"
    exit 1
fi

# Terraform validation
if [[ "$RUN_TERRAFORM" == true ]]; then
    print_status "Running Terraform validation..."
    if command_exists terraform; then
        if terraform validate; then
            print_success "Terraform validation passed"
        else
            print_error "Terraform validation failed"
            exit 1
        fi
    else
        print_error "Terraform is not installed"
        exit 1
    fi
fi

# Terraform formatting
if [[ "$RUN_FORMAT" == true ]]; then
    print_status "Checking Terraform formatting..."
    if command_exists terraform; then
        # Check if files need formatting
        if terraform fmt -check -recursive; then
            print_success "Terraform formatting is correct"
        else
            print_warning "Some files need formatting. Run 'terraform fmt -recursive' to fix"
        fi
    else
        print_error "Terraform is not installed"
        exit 1
    fi
fi

# TFLint validation
if [[ "$RUN_LINT" == true ]]; then
    print_status "Running TFLint validation..."
    if command_exists tflint; then
        if tflint; then
            print_success "TFLint validation passed"
        else
            print_warning "TFLint found issues (see output above)"
        fi
    else
        print_warning "TFLint is not installed. Install with: go install github.com/terraform-linters/tflint/cmd/tflint@latest"
    fi
fi

# Security scanning
if [[ "$RUN_SECURITY" == true ]]; then
    print_status "Running security scanning..."
    
    # Try Terrascan
    if command_exists terrascan; then
        print_status "Running Terrascan security scan..."
        if terrascan scan; then
            print_success "Terrascan security scan passed"
        else
            print_warning "Terrascan found security issues (see output above)"
        fi
    else
        print_warning "Terrascan is not installed. Install with: curl -L \"\$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -m 1 \"https://.*_Linux_x86_64.tar.gz\")\" | tar -xz terrascan && sudo mv terrascan /usr/local/bin/"
    fi
    
    # Try Checkov
    if command_exists checkov; then
        print_status "Running Checkov security scan..."
        if checkov -d . --framework terraform; then
            print_success "Checkov security scan passed"
        else
            print_warning "Checkov found security issues (see output above)"
        fi
    else
        print_warning "Checkov is not installed. Install with: pip install checkov"
    fi
fi

# Additional checks
print_status "Running additional checks..."

# Check for required files
REQUIRED_FILES=("main.tf" "variables.tf" "outputs.tf" "versions.tf" "README.md")
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "✓ $file exists"
    else
        print_error "✗ $file is missing"
    fi
done

# Check for examples directory
if [[ -d "examples" ]]; then
    print_success "✓ Examples directory exists"
    EXAMPLE_COUNT=$(find examples -name "main.tf" | wc -l)
    print_status "Found $EXAMPLE_COUNT example configurations"
else
    print_warning "Examples directory is missing"
fi

# Check for test directory
if [[ -d "test" ]]; then
    print_success "✓ Test directory exists"
else
    print_warning "Test directory is missing"
fi

# Check for scripts directory
if [[ -d "scripts" ]]; then
    print_success "✓ Scripts directory exists"
else
    print_warning "Scripts directory is missing"
fi

# Check for LICENSE file
if [[ -f "LICENSE" ]]; then
    print_success "✓ LICENSE file exists"
else
    print_warning "LICENSE file is missing"
fi

# Check for Makefile
if [[ -f "Makefile" ]]; then
    print_success "✓ Makefile exists"
else
    print_warning "Makefile is missing"
fi

print_success "Module validation completed!"

# Summary
echo ""
print_status "Validation Summary:"
print_status "- Terraform validation: $([[ "$RUN_TERRAFORM" == true ]] && echo "✓" || echo "⏭")"
print_status "- Formatting check: $([[ "$RUN_FORMAT" == true ]] && echo "✓" || echo "⏭")"
print_status "- Linting: $([[ "$RUN_LINT" == true ]] && echo "✓" || echo "⏭")"
print_status "- Security scanning: $([[ "$RUN_SECURITY" == true ]] && echo "✓" || echo "⏭")"

echo ""
print_status "Next steps:"
print_status "1. Review any warnings or errors above"
print_status "2. Run 'terraform fmt -recursive' to format code if needed"
print_status "3. Test the module with one of the examples"
print_status "4. Consider adding more comprehensive tests" 