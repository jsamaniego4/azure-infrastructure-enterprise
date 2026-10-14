#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../terraform"
for tool in terraform az python3 ssh; do
  command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }
done
# Select the subscription from the deployed resource ID, not the current CLI default.
vnet_id=$(terraform output -raw vnet_id)
subscription=$(printf '%s' "$vnet_id" | cut -d/ -f3)
rg=$(terraform output -raw resource_group)
vm=$(terraform output -raw vm_name)
ip=$(terraform output -raw vm_public_ip)
principal=$(terraform output -raw vm_principal_id)
alert=$(terraform output -raw cpu_alert_name)
az vm get-instance-view --subscription "$subscription" -g "$rg" -n "$vm" -o json | python3 -c '
import json,sys
v=json.load(sys.stdin)
assert any(s["code"] == "PowerState/running" for s in v["instanceView"]["statuses"]), "VM is not running"
assert v["osProfile"]["linuxConfiguration"]["disablePasswordAuthentication"], "Password authentication enabled"
assert v["identity"]["type"] == "SystemAssigned", "Managed identity missing"
print("PASS: VM running, SSH keys required, managed identity enabled")'
az network nsg show --subscription "$subscription" -g "$rg" -n "${vm%-vm}-nsg" -o json | python3 -c '
import ipaddress,json,sys
rules=json.load(sys.stdin)["securityRules"]
assert len(rules)==1, "Unexpected custom NSG rules"
r=rules[0]
n=ipaddress.ip_network(r["sourceAddressPrefix"])
assert n.version==4 and n.prefixlen==32 and not n.network_address.is_unspecified
assert r["destinationPortRange"]=="22" and r["access"]=="Allow" and r["direction"]=="Inbound"
print("PASS: custom inbound SSH rule restricted to one IPv4 host")'
az role assignment list --subscription "$subscription" --assignee-object-id "$principal" --scope "/subscriptions/$subscription/resourceGroups/$rg" -o json | python3 -c '
import json,sys
assert any(r["roleDefinitionName"]=="Reader" for r in json.load(sys.stdin)), "Reader assignment missing"
print("PASS: resource group Reader role present")'
az monitor metrics alert show --subscription "$subscription" -g "$rg" -n "$alert" -o json | python3 -c '
import json,sys
v=json.load(sys.stdin)
assert v["enabled"] and v["actions"], "Alert disabled or notification action missing"
print("PASS: CPU alert enabled with notification action")'
ssh -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=ask "azureuser@$ip" 'uname -sr; systemctl is-system-running --wait'
printf '%s\n' 'Live checks passed. Alert delivery and blocked-source SSH still require separate tests.'
