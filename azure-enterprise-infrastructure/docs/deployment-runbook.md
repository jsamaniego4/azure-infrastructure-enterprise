# Deployment and teardown

This is a single-VM lab, with a public IP for tightly restricted administration. It has no high availability, workload application, backup policy, or centralized guest logs. The managed identity has Reader access only within the lab resource group.

1. Install Azure CLI and Terraform 1.9 or newer (below 2.0). Run `az login`, select your sandbox subscription with `az account set --subscription ID`, and inspect `az account show`.
2. The deploying identity needs resource creation rights and role assignment rights, such as Contributor plus Role Based Access Control Administrator scoped to the target resource group, or Owner at the appropriate scope. Contributor alone cannot create the Reader assignment. If you cannot create a resource group, arrange for an authorized administrator to provision and import it first.
3. Ensure `Microsoft.Compute`, `Microsoft.Network`, and `Microsoft.Insights` providers are registered. Check VM quota, region availability, and policy restrictions. The AzureRM provider may attempt automatic registration; have an administrator register required providers if your identity cannot do so.
4. Create an SSH key with `ssh-keygen -t ed25519`. Copy only the `.pub` contents into the local variables file. Use your current public IPv4 address followed by `/32` and a real alert email. Replace the example subscription UUID. Never use the example documentation IP.
5. From the project directory: `cp terraform/terraform.tfvars.example terraform/terraform.tfvars`, edit values, and run `bash scripts/preflight.sh`. Review the subscription, resource names, role scope, cost, and proposed changes. Run `terraform apply tfplan` from `terraform/` when ready.
6. Run `bash scripts/validate-live.sh` from the project directory. Follow `TESTING.md` for alert delivery and negative connectivity tests. Capture sanitized evidence.
7. From `terraform/`, run `terraform plan -destroy -out=destroy.tfplan`, review it, then `terraform apply destroy.tfplan`. Verify `az group exists --subscription ID --name PREFIX-rg` returns `false`, and check Azure billing for residual resources.

Local state is deliberately used for a single-user lab. Keep it securely backed up until teardown; losing it prevents straightforward management of existing resources. Plans and state can contain personal settings and credentials and are gitignored. Do not upload them as proof. For team use, migrate state to a separately managed Azure Storage backend with access controls and locking before collaboration. Commit `.terraform.lock.hcl` and use `terraform init -upgrade` only for intentional provider updates.

If apply partially fails, inspect the error and run a fresh plan against the same state. Do not delete state or reapply an old plan. RBAC propagation may delay identity access. A changed public IP requires a new plan/apply updating the allowlist. Updating SSH public keys on an existing VM may require replacement; inspect the plan first.

## Provider lock file across platforms

After intentionally updating a provider, generate signed checksums for both the Linux GitHub runner and Apple Silicon development machines before committing the lock file:

```sh
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
```

CI uses `-lockfile=readonly`. Without the Linux package's `h1` checksum, initialization can verify its downloaded ZIP using `zh` checksums, but subsequent validation can reject the extracted package. Keep checksum verification enabled and commit the cross-platform lock file. Add other platforms explicitly if needed.
