### Lets try using Google Cloud Platform

# Pre-requisites
> ***Note --->*** Setup of pre-requisites is out of this scope, please use the guiding urls for each topic

- Google Cloud Account (free trial: https://cloud.google.com/free)  
***--->*** Setup a Project and Billing  
***--->*** Create a Service Account and Service Account json Key file (https://cloud.google.com/iam/docs/creating-managing-service-account-keys)  
- Terraform > 1.0.6 installed

# Pre-steps

## in GCP
- Clean up firewall rules
- Add additional roles to the Service account
- Pre-enable some google APIs

# Deploy
- Clone this repository
- Add your Service Account json key file into the folder
- Change `project_id` value where it is applicable
- Change `GCLOUD_TF_BUCKET_NAME` value (need to change it to a unique name)
- Execute the following terraform commands

##


