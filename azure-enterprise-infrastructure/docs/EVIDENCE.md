# Deployment evidence checklist (fill in only after running)

Local checks are recorded separately in [local-validation.md](local-validation.md). The deployment items below remain pending.

- [ ] Terraform plan command succeeded; date: ______
- [ ] Terraform apply succeeded; subscription (redacted): ______
- [ ] Azure resource screenshot stored privately/redacted in `docs/evidence/`
- [ ] SSH from allowlisted IP succeeded; command/output (redacted): ______
- [ ] NSG restriction verified; method: ______
- [ ] VM identity has Reader access scoped to the lab resource group; evidence: ______
- [ ] CPU alert exists; triggered? (yes/no, do not claim it fired if not): ______
- [ ] GitHub Actions run URL: ______
- [ ] Terraform destroy completed; date: ______
- [ ] Demo recording URL: ______

Deployment evidence is **not** pre-filled, because no deployment has been run. Store raw evidence privately; only publish sanitized copies. Add timestamps and methods so readers can distinguish resource existence, successful notifications, and tested recovery.
