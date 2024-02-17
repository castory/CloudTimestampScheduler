Project: Cloud Timestamp Scheduler

Description of repo folders/structure

 Folders contain:
 Project-1 ->terraform ->providers 
                       ->terraform.tfstate
            ->terraform.locl.hcl
            ->example_lambda_function.zip
                       ->lambda_fuction.py
            ->main.ft

Repository Structure:
Project-1:Contain all files of this project.
terraform/: Contains Terraform configuration files for AWS resources and remote terraform.tfstate which store in S3
terraform.lock.hcl: For track and select provider versions.
example_lambda_function.zip: Contain lambda fuction code in zip file, include lambda_fuction.py.
main.tf: Defines AWS resources (S3 bucket, KMS key, API Gatew.ay, Lambda, CloudWatch events).
outputs.tf: Defines output values to be displayed after deployment.
README.md: Documentation file providing information on repository structure, deployment, and tear-down instructions.

Deployment Instructions and Dependencies:
AWS Account Setup:
Ensure you have an AWS account with the necessary permissions.
Set up AWS CLI with proper credentials.

Terraform Deployment:
Navigate to the terraform/ directory.
Create a folder which you will work on Project-1
Add all files and dependencies
Open a folder via visual studio code editor.
For security purposes I use variables for sensitive information.
Run terraform init to initialize the working directory.
Run TF_VAR_aws_access_key="your_aws_access_key" TF_VAR_aws_secret_key="your_aws_secret_key" TF_VAR_kms_key_arn="your_kms_key_arn" terraform plan
Run TF_VAR_aws_access_key="your_aws_access_key" TF_VAR_aws_secret_key="your_aws_secret_key" TF_VAR_kms_key_arn="your_kms_key_arn" terraform apply to create AWS resources.
Review the changes, type yes to confirm, and wait for the deployment to complete.

Lambda Function Deployment:
Upload your Lambda function code in the example_lambda_function/ directory.
Update the filename attribute in terraform/main.tf to point to your Lambda function code file.

Access API Gateway:
After deployment, the API Gateway endpoint will be displayed in the Terraform output (api_gateway_url).
Access the HTTP endpoint using the provided URL to retrieve the most recent timestamp.

Tear-Down Instructions:
Navigate to the terraform/ directory.
Run terraform destroy to tear down all created AWS resources.
Review the changes, type yes to confirm, and wait for the destruction to complete.

Clean Up Lambda Function:
Remove the uploaded Lambda function code file.

Verify Deletion:
Verify in the AWS Management Console that all resources created by Terraform have been deleted.


