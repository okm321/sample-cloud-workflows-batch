# sample-cloud-workflows-batch

Cloud Workflows で深夜バッチをオーケストレーションする構成のサンプル。Terraform で一発デプロイできるようになっています。

## ディレクトリ構成

```
.
├── batch-workflows/
│   ├── nightly-batch-success-pattern.yaml   # parent: try/except なし、上流失敗で下流停止
│   ├── nightly-batch-failure-pattern.yaml   # parent: try/except あり、上流失敗でも下流続行 (child を意図的に失敗させる)
│   ├── daily-aggregation.yaml                # child C: 翌00:00 JST まで sys.sleep してから実行
│   ├── data-prep-a.yaml                      # child A: データ準備A
│   ├── data-prep-b.yaml                      # child A: データ準備B
│   ├── business-process.yaml                 # child B: parallel.branches で4並列
│   └── independent-task.yaml                 # child D: nightly-batchとは独立した workflow
└── terraform/
    ├── versions.tf      # Terraform / provider version
    ├── providers.tf     # google provider
    ├── variables.tf     # 入力変数 (project_id, region)
    ├── apis.tf          # 必要なAPIの有効化
    ├── iam.tf           # Service Account + IAM bindings
    ├── workflows.tf     # google_workflows_workflow リソース群
    └── outputs.tf       # 出力
```

## デモする4つのパターン

### ① Parent / Child Workflow 構成

`nightly-batch-*.yaml` (parent) が `googleapis.workflowexecutions.v1.projects.locations.workflows.executions.run` Connector で child workflow を同期呼び出しする構成です。`connector_params.timeout` のデフォルトが 1800秒(30分)なので、長時間動くchildを呼ぶときは明示的に伸ばす必要がある点に注意。

### ② 日次集計バッチの00:00待ち

`daily-aggregation.yaml` で実装。parent から `parent_started_at_unix` を argument で受け取り、「parent起動日の翌00:00 (JST)」まで `sys.sleep` で待ってから実行します。

`math.max(0, target_unix - sys.now())` の式によって、既に target を過ぎていれば 0秒 sleep (即実行) になります。

手動実行時に00:00待ちをスキップしたい場合は、parent に対して以下の引数で実行すると `target_unix` が遥か過去になるため sleep が 0秒になります。

```json
{ "parent_started_at_unix": 0 }
```

### ③ 上流が失敗しても下流を走らせたい (try/except)

`nightly-batch-failure-pattern.yaml` で実装。`try/except` 構文を使い、上流stepのエラーを catch して `raise` せずに下流に進めます。「上流が失敗しても下流のバッチは必ず走らせたい」業務要件向けのパターン。

このサンプルでは failure-pattern から呼ばれる child (`data-prep-a` / `business-process`) に `argument: {should_fail: true}` を渡すことで意図的に `raise` させており、try/except が握りつぶす様子が Cloud Logging から確認できます。

- `data-prep` step: parallel の片方 (data-prep-a) が失敗 → `UnhandledBranchError` → 親が catch → business-process へ
- `business-process` step: 4並列の branch_1 だけ失敗 → `UnhandledBranchError` → 親が catch → daily-aggregation へ
- `daily-aggregation` step: try/except で囲っていないため、失敗するとここで workflow も失敗する

対比として、`nightly-batch-success-pattern.yaml` は同じフローを try/except なしで書いた版です。両者の YAML を見比べることで、try/except の有無による挙動の違いが分かります。

### ④ parallel.branches での並列実行

- `nightly-batch-*.yaml` の `run_data_prep` step: data-prep-a と data-prep-b を並列実行
- `business-process.yaml`: 4つの業務処理を並列実行

`parallel.branches` の下に独立した steps の branch を並べると並列実行され、**全branchの完了を待ってから**次の step に進む (join 挙動) という形になります。

## デプロイ手順

### 1. 前提

- Google Cloud プロジェクト

### 2. Terraform 実行

```bash
cd terraform
terraform init
terraform plan -var="project_id=YOUR_PROJECT_ID"
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

## 動作確認・手動実行

```bash
# success pattern を手動実行 (00:00待ちをスキップ)
gcloud workflows run nightly-batch-success-pattern \
  --location=asia-northeast1 \
  --data='{"parent_started_at_unix": 0}'

# failure pattern を手動実行 (00:00待ちをスキップ)
gcloud workflows run nightly-batch-failure-pattern \
  --location=asia-northeast1 \
  --data='{"parent_started_at_unix": 0}'

# daily-aggregation child だけ単独で実行
gcloud workflows run daily-aggregation \
  --location=asia-northeast1 \
  --data='{"parent_started_at_unix": 0}'
```

実行後は Cloud Workflows コンソール または Cloud Logging で各stepの `sys.log` 出力と、failure-pattern では catch されたエラーメッセージを確認できます。

## 参考

- [Cloud Workflows ドキュメント](https://cloud.google.com/workflows/docs)
- [Make an HTTP request (timeout最大値の出典)](https://cloud.google.com/workflows/docs/http-requests?hl=ja)
- [Cloud Workflows: parallel steps](https://cloud.google.com/workflows/docs/reference/syntax/parallel-steps)
- [Cloud Workflows: catching errors (try/except)](https://cloud.google.com/workflows/docs/reference/syntax/catching-errors)
- [Parent and child workflow setup for parallel task execution (Google Cloud Blog)](https://cloud.google.com/blog/products/application-development/setup-parallel-task-execution-with-parent-and-child-workflows)
