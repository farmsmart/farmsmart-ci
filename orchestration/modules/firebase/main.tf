resource "google_project" "default" {
  name            = "${var.namespace}-${var.stage}"
  folder_id       = "${var.folder_id}"
  project_id      = "${var.namespace}-${var.stage}"
  billing_account = "${var.billing_account_id}"
}

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

resource "google_storage_bucket" "farmsmart_backup" {
  name     = "${google_project.default.project_id}_farmsmart_backup"
  project  = "${google_project.default.project_id}"
  location = "${var.region}"
  storage_class = "NEARLINE"
}

//TODO: SERVICE ACCOUNTS

resource "google_kms_key_ring" "default" {
  name     = "farmsmart-keyring"
  project  = "${google_project.default.project_id}"
  location = "${var.region}"

  depends_on = ["google_project_service.cloudkms"]
}

resource "google_kms_crypto_key" "default" {
  name            = "farmsmart-key"
  key_ring        = "${google_kms_key_ring.default.self_link}"
  rotation_period = "1209600s"

  depends_on = ["google_project_service.cloudkms"]
}
