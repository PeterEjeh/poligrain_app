# Poligrain App Database Setup

This directory contains scripts to create the DynamoDB database schema for the Poligrain App.

## Prerequisites

### Option 1: Using Python with boto3 (Recommended)
1. **Python 3.7+** installed
2. **AWS credentials** configured (one of the following):
   - AWS CLI configured (`aws configure`)
   - Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
   - IAM role (if running on EC2)
   - AWS profile configured

### Option 2: Using AWS CLI
1. **AWS CLI** installed and configured
2. **Python 3.7+** (for running the script)

## Database Schema

The database consists of 6 main tables:

1. **Products** - Store product information with category indexing
2. **Orders** - Store order data with user indexing
3. **Transactions** - Store financial transactions with user indexing  
4. **Campaigns** - Store investment campaigns with owner and status indexing
5. **Investments** - Store user investments with user and campaign indexing
6. **Documents** - Store document metadata with owner and campaign indexing

Each table includes appropriate Global Secondary Indexes (GSI) for efficient querying.

## Setup Instructions

### Method 1: Quick Setup (Windows)

1. Double-click `setup_database.bat`
2. The script will:
   - Install required Python packages
   - Run the database creation script
   - Prompt you to add sample data

### Method 2: Manual Python Setup

1. Install required packages:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the database creation script:
   ```bash
   python create_database.py
   ```

3. Follow the prompts to optionally add sample data

### Method 3: Using AWS CLI

1. Ensure AWS CLI is installed and configured:
   ```bash
   aws --version
   aws sts get-caller-identity
   ```

2. Run the CLI-based script:
   ```bash
   python create_database_cli.py
   ```

## What the Scripts Do

### create_database.py
- Creates all 6 DynamoDB tables with proper schemas
- Sets up Global Secondary Indexes for efficient querying
- Uses PAY_PER_REQUEST billing mode (no upfront capacity planning needed)
- Optionally adds sample data for testing
- Provides detailed progress feedback

### create_database_cli.py  
- Alternative method using AWS CLI commands
- Useful if you prefer CLI-based approach
- Checks AWS CLI installation and configuration
- Creates the same table structure as the Python script

## AWS Permissions Required

Your AWS credentials need the following DynamoDB permissions:
- `dynamodb:CreateTable`
- `dynamodb:DescribeTable` 
- `dynamodb:PutItem` (if adding sample data)

Example IAM policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DescribeTable",
                "dynamodb:PutItem"
            ],
            "Resource": "*"
        }
    ]
}
```

## Troubleshooting

### Common Issues

1. **"ResourceInUseException"** - Table already exists
   - This is normal, the script will skip existing tables

2. **"UnauthorizedOperation"** - Insufficient permissions
   - Check your AWS credentials and IAM permissions

3. **"ProvisionedThroughputExceededException"** - Too many requests
   - Wait a few minutes and try again

4. **Python/pip not found**
   - Install Python 3.7+ from https://python.org
   - Make sure Python is added to your PATH

5. **AWS CLI not configured**
   - Run `aws configure` to set up your credentials
   - Or set environment variables

### Verification

After successful creation, you can verify the tables exist:

```bash
# List all tables
aws dynamodb list-tables

# Describe a specific table
aws dynamodb describe-table --table-name Products
```

## Sample Data

The script can optionally create sample data including:
- Sample products (tomatoes, rice)
- Test data for development and testing

## Files Description

- `create_database.py` - Main database creation script (Python + boto3)
- `create_database_cli.py` - Alternative using AWS CLI
- `setup_database.bat` - Windows batch file for quick setup
- `requirements.txt` - Python dependencies
- `DATABASE_SCHEMA.md` - Detailed schema documentation
- Individual `*-table.json` files - Table-specific configurations

## Next Steps

After creating the database:

1. Update your application configuration with the correct AWS region
2. Test the database connection in your app
3. Consider setting up monitoring and backups
4. Review and adjust table capacity if needed

## Support

For issues with this setup:
1. Check the troubleshooting section above
2. Verify your AWS credentials and permissions
3. Check AWS CloudWatch logs for detailed error messages
