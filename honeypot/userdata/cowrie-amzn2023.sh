#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Cowrie userdata (Amazon Linux 2023) at $(date -u)"

# Vars
LOG_GROUP="/honeypot/cowrie"
COWRIE_USER="cowrie"
COWRIE_HOME="/opt/cowrie"
COWRIE_SRC="${COWRIE_HOME}/cowrie"
VENV="${COWRIE_HOME}/venv"

# Packages (AL2023)
dnf -y update
dnf -y install git gcc gcc-c++ make openssl-devel libffi-devel bzip2 jq \
               python3.11 python3.11-devel amazon-cloudwatch-agent

PYBIN="/usr/bin/python3.11"
$PYBIN -V

# User & dirs
id -u "${COWRIE_USER}" >/dev/null 2>&1 || useradd --system --create-home --home-dir "${COWRIE_HOME}" "${COWRIE_USER}"
mkdir -p "${COWRIE_HOME}"; chown -R ${COWRIE_USER}:${COWRIE_USER} "${COWRIE_HOME}"

# Cowrie source
if [ ! -d "${COWRIE_SRC}" ]; then
  sudo -u ${COWRIE_USER} git clone https://github.com/cowrie/cowrie.git "${COWRIE_SRC}"
fi

# Venv + deps + install cowrie (editable)
sudo -u ${COWRIE_USER} ${PYBIN} -m venv "${VENV}"
sudo -u ${COWRIE_USER} bash -lc "source ${VENV}/bin/activate && \
  pip install --upgrade pip setuptools wheel && \
  pip install -r ${COWRIE_SRC}/requirements.txt && \
  pip install -e ${COWRIE_SRC}"

# Configs (explicit paths that Cowrie actually uses)
mkdir -p "${COWRIE_SRC}/etc" "${COWRIE_SRC}/var/log/cowrie" "${COWRIE_SRC}/var/run"
cat > "${COWRIE_SRC}/etc/cowrie.cfg" <<'INI'
[ssh]
enabled = true
listen_endpoints = tcp:2222:interface=0.0.0.0

[telnet]
enabled = true
listen_endpoints = tcp:2223:interface=0.0.0.0

[output_jsonlog]
enabled = true
logfile = var/log/cowrie/cowrie.json

[output_textlog]
enabled = true
logfile = var/log/cowrie/cowrie.log
INI
chown -R ${COWRIE_USER}:${COWRIE_USER} "${COWRIE_SRC}"

# CloudWatch Agent config (match real file paths)
cat > "${COWRIE_HOME}/cloudwatch-agent.json" <<JSON
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "${COWRIE_SRC}/var/log/cowrie/cowrie.log",
            "log_group_name": "${LOG_GROUP}", "log_stream_name": "{instance_id}", "timezone": "UTC" },
          { "file_path": "${COWRIE_SRC}/var/log/cowrie/cowrie.json",
            "log_group_name": "${LOG_GROUP}", "log_stream_name": "{instance_id}-json", "timezone": "UTC" }
        ]
      }
    }
  }
}
JSON
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:${COWRIE_HOME}/cloudwatch-agent.json -s || true

# systemd unit (use the venv CLI)
cat > /etc/systemd/system/cowrie.service <<'UNIT'
[Unit]
Description=Cowrie Honeypot
After=network.target
[Service]
Type=simple
User=cowrie
Group=cowrie
WorkingDirectory=/opt/cowrie/cowrie
ExecStart=/opt/cowrie/venv/bin/cowrie start
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable cowrie
systemctl start cowrie || echo "Cowrie failed to start—see /var/log/user-data.log"
echo "Completed Cowrie userdata (AL2023) at $(date -u)"
