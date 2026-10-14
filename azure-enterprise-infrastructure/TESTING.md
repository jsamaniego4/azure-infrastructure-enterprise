# Validation

From `azure-enterprise-infrastructure/terraform`:

```sh
terraform init -backend=false -input=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
terraform test
```

Mock-provider tests check key-only authentication, managed identity, an allowlisted SSH rule, Reader access, and a notification action. Negative cases reject global, broad, and IPv6 SSH CIDRs. Mock tests do not call Azure or prove that Azure will accept a deployment.

After applying, run `../scripts/validate-live.sh` from `terraform/`. Authenticate with Azure CLI first. Establish the SSH host key using a trusted channel before running; the script never disables host-key checking. Your default SSH identity must match the configured public key (or configure `~/.ssh/config`).

Record timestamps, commands, results, and sanitized screenshots in `docs/EVIDENCE.md`. From a separate, nonallowlisted network, test port 22 with `nc -vz -w 5 VM_IP 22`; expect timeout. NSG default rules permit traffic within the VNet, so this test must use an external source. A timeout alone does not identify the NSG as the cause; inspect effective NSG rules as well.

For a bounded CPU alert test on the VM:

```sh
pids=""
for cpu in $(seq 1 "$(nproc)"); do yes >/dev/null & pids="$pids $!"; done
sleep 420
kill $pids
```

Run this only on the disposable lab VM. Burstable VM credits may affect the CPU metric. Check the five-minute CPU average, alert state, and actual email delivery; allow ingestion time. Stop load with `pkill -x yes` if interrupted. Do not claim delivery from merely seeing the alert resource.

For recovery evidence, reproduce a concrete failure (for example, change your local SSH key selection), capture the error, diagnose with `ssh -v`, restore the correct key, and record the successful retry in the incident report. Never fabricate logs or results.
