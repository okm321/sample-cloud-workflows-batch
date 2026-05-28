output "workflow_ids" {
  description = "作成されたすべての workflow のID"
  value = {
    nightly_batch_success_pattern = google_workflows_workflow.nightly_batch_success_pattern.id
    nightly_batch_failure_pattern = google_workflows_workflow.nightly_batch_failure_pattern.id
    daily_aggregation             = google_workflows_workflow.daily_aggregation.id
    data_prep_a                   = google_workflows_workflow.data_prep_a.id
    data_prep_b                   = google_workflows_workflow.data_prep_b.id
    business_process              = google_workflows_workflow.business_process.id
    independent_task              = google_workflows_workflow.independent_task.id
  }
}

output "workflow_invoker_sa_email" {
  description = "Workflows実行用のService Accountメール (Cloud Run Jobs側で roles/run.invoker を付与する対象)"
  value       = google_service_account.workflow_invoker.email
}
