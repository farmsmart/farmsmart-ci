resource "google_project" "default" {
  name            = "${var.namespace}-${var.stage}"
  folder_id       = "${var.folder_id}"
  project_id      = "${var.namespace}-${var.stage}"
  billing_account = "${var.billing_account_id}"
}

# resource "null_resource" "attach_billing" {
#   provisioner "local-exec" {
#     command     = "gcloud beta billing projects link ${google_project.default.project_id} --billing-account=${var.billing_account_id}"
#   }

#   depends_on = ["google_project.default"]
  
# }

resource "google_project_service" "cloudresourcemanager" {
  project                    = "${google_project.default.project_id}"
  service                    = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "cloudkms" {
  project                    = "${google_project.default.project_id}"
  service                    = "cloudkms.googleapis.com"
}

resource "google_project_service" "firebase" {
  project                    = "${google_project.default.project_id}"
  service                    = "firebase.googleapis.com"
}

resource "google_project_service" "firebaserules" {
  project                    = "${google_project.default.project_id}"
  service                    = "firebaserules.googleapis.com"
}

resource "google_project_service" "sheets" {
  project                    = "${google_project.default.project_id}"
  service                    = "sheets.googleapis.com"
}

resource "google_project_service" "appengine" {
  project                    = "${google_project.default.project_id}"
  service                    = "appengine.googleapis.com"
}

resource "google_storage_bucket" "firestore_backup" {
  name     = "${google_project.default.project_id}_firestore_backup"
  project  = "${google_project.default.project_id}"
  location = "${var.region}"
  storage_class = "NEARLINE"
}

//TODO: SERVICE ACCOUNTS

resource "google_kms_key_ring" "default" {
  name     = "farmsmart-keyring"
  project  = "${google_project.default.project_id}"
  location = "${var.region}"
}

resource "google_kms_crypto_key" "default" {
  name            = "farmsmart-key"
  key_ring        = "${google_kms_key_ring.default.self_link}"
  rotation_period = "1209600s"

  # Note: CryptoKeys cannot be deleted from Google Cloud Platform. Destroying a Terraform-managed CryptoKey will remove it from state and 
  # delete all CryptoKeyVersions, rendering the key unusable, but will not delete the resource on the server. 
  # When Terraform destroys these keys, any data previously encrypted with these keys will be irrecoverable. 
  # For this reason, it is strongly recommended that you add lifecycle hooks to the resource to prevent accidental destruction.
  lifecycle {
    prevent_destroy = true
  }

  depends_on = ["google_project_service.cloudkms"]
}

resource "null_resource" "firebase_setup" {
  provisioner "local-exec" {
    command     = "python3 ./data/firebase-init.py"
    working_dir = "${path.module}"

    environment {
      project_id           = "${google_project.default.project_id}"
      service_account_file = "${var.service_account_file}"
    }
  }
  depends_on = ["google_project_service.firebase", "google_project_service.cloudresourcemanager"]
}