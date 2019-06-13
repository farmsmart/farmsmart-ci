#!/bin/bash

# Stop if there are any errors
set -e

# Configuration Variables, tweak these based upon changes to GCP.
PROJECT_ROLES='roles/storage.admin'
ORG_ROLES='roles/resourcemanager.projectCreator roles/billing.admin roles/owner roles/resourcemanager.folderCreator '
REQUIRED_SERVICES='cloudresourcemanager.googleapis.com cloudbilling.googleapis.com cloudkms.googleapis.com iam.googleapis.com firebase.googleapis.com'

# Script Root for this script, used to source environment.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Import the environment variables
source $DIR/environment.sh

# Extract and validate the organisation from gcloud configuration
CURRENT_ORG=$(gcloud organizations list --format=json | jq ".[] | select(.name | contains(\"organizations/$TF_VAR_org_id\"))")

DIRTY=0
if [[ "$CURRENT_ORG" == "" ]]
  then
    echo -e "Organisation ID: The Organisation ID listed in the \$TF_VAR_org_id variables ($TF_VAR_org_id) doesn't appear to be configured in gcloud."
    DIRTY=1
  else
    echo -e "Organisation ID: The Organisation ID ($TF_VAR_org_id) is configured in gcloud."
fi

# Extract and validate the billing account from gcloud configuration
CURRENT_BILLING_ACT=$(gcloud beta billing accounts list --format=json | jq ".[] | select(.name | contains(\"billingAccounts/$TF_VAR_billing_account\"))")

if [[ "$CURRENT_BILLING_ACT" == "" ]]
  then
    echo -e "Billing Account: The Billing Account listed in the \$TF_VAR_billing_account variables ($TF_VAR_billing_account) doesn't appear to be configured in gcloud."
    DIRTY=1
  else
    echo -e "Billing Account: The Billing Account ($TF_VAR_billing_account) is configured in gcloud."
fi

if [[ "$TF_VAR_admin_project" == "" ]]
  then
    echo -e "Admin Project: The Admin Project in the \$TF_VAR_admin_project variables doesn't appear to be set."
    DIRTY=1
  else
    echo -e "Admin Project: The Admin Project ($TF_VAR_admin_project) is set."
fi

if [[ "$DIRTY" == "1" ]]
  then
    echo -e "Error: One of more guard clauses failed check environment.sh and gcloud configuration matches up"
    exit 1
fi

# Create the project if it does not already exist
EXISTING_PROJECT=$(gcloud projects list --filter=name:${TF_VAR_admin_project} --format=json)

if [[ "$EXISTING_PROJECT" == "[]" ]]
  then
    echo -e "Admin Project: The Admin Project ($TF_VAR_admin_project) does not exist yet, creating it and linking it to the billing account."
    gcloud projects create ${TF_VAR_admin_project} --organization ${TF_VAR_org_id} --set-as-default
    gcloud beta billing projects link ${TF_VAR_admin_project} --billing-account ${TF_VAR_billing_account}
  else
    echo -e "Admin Project: The Admin Project ($TF_VAR_admin_project) already exists."
fi

TF_PROJECT=$(gcloud projects list --format='value(projectNumber)' --filter=name:$TF_VAR_admin_project)
echo -e "Admin Project: The Admin Project ($TF_VAR_admin_project) ID is $TF_PROJECT."

# Enable the required services

for svc in $REQUIRED_SERVICES
do
  echo -e "Admin Project: Enabling $svc."
  gcloud services enable "$svc"
done

# Create the user if it does not exist

EXISTING_USER=$(gcloud iam service-accounts list --format=json --filter=name:terraform)

if [[ "$EXISTING_USER" == "[]" ]]
  then
    echo -e "Terraform User: The Terraform does not exist yet, creating it and granting permissions."
    gcloud iam service-accounts create terraform --display-name "Terraform admin account"
 
    echo -e "Terraform User: Downloading JSON credentials."
    gcloud iam service-accounts keys create ${TF_CREDS} --iam-account terraform@${TF_VAR_admin_project}.iam.gserviceaccount.com
  else
    echo -e "Terraform User: The Admin Project ($TF_VAR_admin_project) already exists."
fi

# Assign roles for the user, don't need to check first as this works repeatedly

for prole in $PROJECT_ROLES
do
  echo -e "Terraform User: Granting $prole role to the Admin Project ($TF_VAR_admin_project)."
  gcloud projects add-iam-policy-binding ${TF_VAR_admin_project} --member serviceAccount:terraform@${TF_VAR_admin_project}.iam.gserviceaccount.com --role $prole
done

for orole in $ORG_ROLES
do
  echo -e "Terraform User: Granting $orole role to the organisation."
  gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} --member serviceAccount:terraform@${TF_VAR_admin_project}.iam.gserviceaccount.com --role $orole
done

# Create terraform backend

TF_STATE_BUCKET=gs://${TF_VAR_admin_project}-tf-state

if (gsutil ls ${TF_STATE_BUCKET} &>/dev/null)
  then
    echo -e "Admin Project: The Terraform state bucket ($TF_STATE_BUCKET) for ($TF_VAR_admin_project) already exists."
  else
    echo -e "Admin Project: Creating Terraform state bucket ($TF_STATE_BUCKET) for ($TF_VAR_admin_project)."
    gsutil mb -p ${TF_VAR_admin_project} ${TF_STATE_BUCKET}
    gsutil versioning set on ${TF_STATE_BUCKET}
fi

# All done

echo -e "Bootstrap: Bootstrapping Complete."