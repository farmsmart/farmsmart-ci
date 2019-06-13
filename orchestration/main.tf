terraform {
  backend "gcs" {
    bucket = "farmsmart-admin-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  region = "${var.region}"
}

resource "google_folder" "default" {
  display_name = "Farmsmart"
  parent       = "organizations/${var.organisation_id}"
}

data "google_folder" "default" {
  folder     = "${google_folder.default.name}"
  depends_on = ["google_folder.default"]
}

module "firebase" {
  source = "./modules/firebase"

  billing_account_id   = "${var.billing_account_id}"
  namespace            = "${var.namespace}"
  folder_id            = "${data.google_folder.default.id}"
  stage                = "${var.stage}"
  region               = "${var.region}"
  service_account_file = "${var.service_account_file}"
}
