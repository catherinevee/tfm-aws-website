#!/bin/bash

# AWS Static Website Content Deployment Script
# This script helps upload website content to the S3 bucket

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --bucket BUCKET_NAME    S3 bucket name (required)"
    echo "  -s, --source SOURCE_PATH    Source directory path (default: ./website-content)"
    echo "  -r, --region REGION         AWS region (default: us-east-1)"
    echo "  -d, --dry-run               Show what would be uploaded without actually uploading"
    echo "  -c, --cache-invalidation    Invalidate CloudFront cache after upload"
    echo "  -i, --distribution-id ID    CloudFront distribution ID for cache invalidation"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -b my-website-bucket"
    echo "  $0 -b my-website-bucket -s ./my-website-files"
    echo "  $0 -b my-website-bucket -d"
    echo "  $0 -b my-website-bucket -c -i E1234567890ABC"
}

# Default values
BUCKET_NAME=""
SOURCE_PATH="./website-content"
AWS_REGION="us-east-1"
DRY_RUN=false
CACHE_INVALIDATION=false
DISTRIBUTION_ID=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -s|--source)
            SOURCE_PATH="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -c|--cache-invalidation)
            CACHE_INVALIDATION=true
            shift
            ;;
        -i|--distribution-id)
            DISTRIBUTION_ID="$2"
            shift 2
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

# Validate required parameters
if [[ -z "$BUCKET_NAME" ]]; then
    print_error "Bucket name is required"
    show_usage
    exit 1
fi

# Check if source directory exists
if [[ ! -d "$SOURCE_PATH" ]]; then
    print_error "Source directory does not exist: $SOURCE_PATH"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if bucket exists
if ! aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    print_error "Bucket '$BUCKET_NAME' does not exist or you don't have access to it."
    exit 1
fi

print_status "Starting content deployment..."
print_status "Bucket: $BUCKET_NAME"
print_status "Source: $SOURCE_PATH"
print_status "Region: $AWS_REGION"
print_status "Dry run: $DRY_RUN"

# Build sync command
SYNC_CMD="aws s3 sync \"$SOURCE_PATH\" \"s3://$BUCKET_NAME\" --region \"$AWS_REGION\""

# Add dry run flag if specified
if [[ "$DRY_RUN" == true ]]; then
    SYNC_CMD="$SYNC_CMD --dryrun"
    print_warning "DRY RUN MODE - No files will be uploaded"
fi

# Execute sync command
print_status "Syncing files to S3..."
if eval "$SYNC_CMD"; then
    if [[ "$DRY_RUN" == true ]]; then
        print_success "Dry run completed successfully"
    else
        print_success "Files uploaded successfully to S3"
    fi
else
    print_error "Failed to sync files to S3"
    exit 1
fi

# Handle cache invalidation
if [[ "$CACHE_INVALIDATION" == true ]]; then
    if [[ -z "$DISTRIBUTION_ID" ]]; then
        print_warning "Cache invalidation requested but no distribution ID provided"
        print_status "You can manually invalidate cache using:"
        print_status "aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths \"/*\""
    else
        print_status "Invalidating CloudFront cache..."
        if aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*" --region "$AWS_REGION"; then
            print_success "Cache invalidation initiated successfully"
        else
            print_error "Failed to invalidate cache"
            exit 1
        fi
    fi
fi

print_success "Deployment completed successfully!"

# Show next steps
echo ""
print_status "Next steps:"
print_status "1. Wait for CloudFront distribution to deploy (usually 5-15 minutes)"
print_status "2. Test your website at the CloudFront URL"
print_status "3. If using a custom domain, ensure DNS is properly configured"
print_status "4. Monitor CloudFront metrics in the AWS Console" 