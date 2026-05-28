resource "google_project_service" "workflows" {
  service                    = "workflows.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "cloud_run" {
  service                    = "run.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "iam" {
  service                    = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "logging" {
  service                    = "logging.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
