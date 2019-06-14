# Farmsmart backend infrastructure

Infrastructure as Code for farmsmart created with terraform version 0.11.14

## Run

`cd orchestration`

`terraform init`

`terraform apply`

This will create the infrastructure for a firebase project based on the variable `stage` in `./orchestration/variables.tf` => `farmsmart_<stage>`

- Project creation
- Enable necessary API's
- Backup bucket
- Managed keys


## Manual steps required

There are some manual steps required following a run of terraform to configure the environment.

- Create a new firebase project linked to the google project https://console.firebase.google.com/u/0/
- In firebase console, click firestore and create a firestore database.
- In firebase console, click Storage and create the default bucket.
- In firebase console, Enable email & password sign in method in authentication. 

### Integrate with flamelink

Once the above steps are complete the project can be integrated with Flamelink, Add a new project https://app.flamelink.io/dashboard.


## Outstanding work

- Add policies to backup bucket - rention policy to prevent early deletion & lifecycle rules to remove old data.
- Implement multi environments with 1. terraform workspaces and shared global resources or 2. Define environments in code.
- Curerntly deletion of firebase module has issues which requires manual intevention eg. Manually delete the project and remove from terraform state with `terraform state rm module.firebase`.
- Implement infrastructure provisioning into CircleCI.
