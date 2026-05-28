variable "project_id" {
  description = "デプロイ先のGoogle CloudプロジェクトID"
  type        = string
}

variable "region" {
  description = "Workflows / Service Account を作成するリージョン"
  type        = string
  default     = "asia-northeast1"
}
