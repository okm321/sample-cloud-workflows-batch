locals {
  workflows_dir = "${path.module}/../batch-workflows"
}

resource "google_workflows_workflow" "nightly_batch_success_pattern" {
  name            = "nightly-batch-success-pattern"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "成功パターン: try/except なし、上流失敗で下流停止"
  source_contents = file("${local.workflows_dir}/nightly-batch-success-pattern.yaml")

  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "nightly_batch_failure_pattern" {
  name            = "nightly-batch-failure-pattern"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "失敗パターン: try/except あり、上流失敗でも下流続行"
  source_contents = file("${local.workflows_dir}/nightly-batch-failure-pattern.yaml")

  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "daily_aggregation" {
  name            = "daily-aggregation"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "前日データの日次集計 (parent起動日の翌00:00 JSTまで待ってから実行)"
  source_contents = file("${local.workflows_dir}/daily-aggregation.yaml")

  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "data_prep_a" {
  name            = "data-prep-a"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "データ準備A"
  source_contents = file("${local.workflows_dir}/data-prep-a.yaml")

  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "data_prep_b" {
  name            = "data-prep-b"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "データ準備B"
  source_contents = file("${local.workflows_dir}/data-prep-b.yaml")

  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "business_process" {
  name            = "business-process"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "業務処理 (parallel.branches で4並列)"
  source_contents = file("${local.workflows_dir}/business-process.yaml")

  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "independent_task" {
  name            = "independent-task"
  region          = var.region
  service_account = google_service_account.workflow_invoker.email
  description     = "独立系の更新 (nightly-batchとは独立した Cloud Schedulerで起動)"
  source_contents = file("${local.workflows_dir}/independent-task.yaml")

  depends_on = [google_project_service.workflows]
}
