# Local validation record

Date: October 14, 2026. Platform: macOS arm64.

Tools: Terraform 1.9.8; AzureRM provider 4.81.0, installed with Terraform's signed provider verification. Provider selection and checksums are committed in `terraform/.terraform.lock.hcl`.

| Check | Observed result |
| --- | --- |
| `terraform fmt -check -recursive` | Passed |
| `terraform validate` | Passed |
| `terraform test` | 4 passed, 0 failed |
| `bash -n scripts/preflight.sh scripts/validate-live.sh` | Passed |

Tests covered security defaults and rejection of global, broad, and IPv6 SSH CIDRs. They used a mock provider and created no Azure resources. Terraform provider execution required running outside the local sandbox. An initial invalid test public-key fixture was corrected before the passing run.

Azure CLI was unavailable in this workspace. No authenticated Azure plan, apply, live script execution, alert delivery check, teardown, or GitHub Actions run was performed. This record establishes local checks only.
