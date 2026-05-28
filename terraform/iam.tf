resource "google_service_account" "workflow_invoker" {
  account_id   = "workflow-invoker"
  display_name = "Cloud Workflows Invoker"
  description  = "parent/child workflowsの起動とCloud Run Jobs呼び出し用のSA"

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "workflow_invoker_workflows_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_invoker.email}"
}

resource "google_project_iam_member" "workflow_invoker_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.workflow_invoker.email}"
}

resource "google_project_iam_member" "workflow_invoker_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workflow_invoker.email}"
}
