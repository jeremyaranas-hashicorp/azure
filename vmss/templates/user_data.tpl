#!/bin/bash

set -x
exec > >(tee /var/log/terraform-user-data.log|logger -t user-data ) 2>&1

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Starting user data script"

sudo apt install -y jq
sudo useradd vault
sudo groupadd vault
sudo usermod -aG vault vault
sudo usermod -aG wheel vault
echo 'vault ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
sudo mkdir -p /home/vault
sudo chown vault:vault /home/vault
sudo mkdir -p /home/vault/.ssh
sudo chown vault:vault /home/vault/.ssh
sudo chmod 700 /home/vault/.ssh
sudo apt install -y unzip
curl --silent -Lo /tmp/vault.zip https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
unzip /tmp/vault.zip
sudo mv vault /usr/bin
sudo mkdir /opt/vault/
sudo chown vault:vault /opt/vault
sudo mkdir /etc/vault.d
sudo chown vault:vault /opt/vault

# Get the IP addresses of the VMs using the Instance Metadata Service 
PRIVATE_IP=$(curl -H "Metadata: true" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0?api-version=2021-02-01" | jq -r .privateIpAddress)
PUBLIC_IP=$(curl -H "Metadata: true" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0?api-version=2021-02-01" | jq -r .publicIpAddress)

cat > /etc/vault.d/license.hclic << EOL
${vault_license}
EOL

cat > /etc/vault.d/server.hcl << EOL
listener "tcp" {
    address = "0.0.0.0:8200"
    cluster_address = "0.0.0.0:8201"
    tls_disable = 1
}

storage "raft" {
  path = "/opt/vault/"
  retry_join {
    auto_join_scheme = "http"
    auto_join = "provider=azure subscription_id=${azure_sub_id} tenant_id=${azure_tenant_id} resource_group=${azure_rg} vm_scale_set=${azure_vmss} secret_access_key=${azure_secret} client_id=${azure_sp_client_id}"
  }
}

api_addr = "http://$PUBLIC_IP:8200"
cluster_addr = "http://$PRIVATE_IP:8201"

log_level = "debug"
raw_storage_endpoint = true
ui = true
license_path = "/etc/vault.d/license.hclic"
EOL

cat > /etc/systemd/system/vault.service << EOL
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://developer.hashicorp.com/vault/docs
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/server.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=notify
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/server.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity
LimitCORE=0

[Install]
WantedBy=multi-user.target
EOL

logger "User data script complete"