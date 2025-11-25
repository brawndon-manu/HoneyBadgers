#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Cowrie userdata at $(date -u)"

# --------- Vars (edit if needed) ---------
LOG_GROUP="/honeypot/cowrie"
COWRIE_USER="cowrie"
COWRIE_HOME="/opt/cowrie"
COWRIE_PORT_SSH=2222
COWRIE_PORT_TELNET=2223
CLOUDWATCH_AGENT_CONFIG="${COWRIE_HOME}/cloudwatch-agent.json"
# -----------------------------------------

yum update -y
yum install -y git gcc openssl-devel libffi-devel bzip2 make curl jq python3 python3-devel python3-virtualenv

# Create cowrie user and dirs
id -u "${COWRIE_USER}" >/dev/null 2>&1 || useradd --system --create-home --home-dir "${COWRIE_HOME}" "${COWRIE_USER}"
mkdir -p "${COWRIE_HOME}"
chown -R ${COWRIE_USER}:${COWRIE_USER} "${COWRIE_HOME}"

# Clone Cowrie
if [ ! -d "${COWRIE_HOME}/cowrie" ]; then
  sudo -u ${COWRIE_USER} git clone https://github.com/cowrie/cowrie.git "${COWRIE_HOME}/cowrie"
fi

# Python venv + deps
sudo -u ${COWRIE_USER} python3 -m venv "${COWRIE_HOME}/venv"
sudo -u ${COWRIE_USER} bash -lc "source ${COWRIE_HOME}/venv/bin/activate && pip install --upgrade pip setuptools wheel && pip install -r ${COWRIE_HOME}/cowrie/requirements.txt"

# Configs: copy provided ones if present; otherwise write minimal defaults
mkdir -p "${COWRIE_HOME}/cowrie/etc" "${COWRIE_HOME}/cowrie/var/log"
if [ -f "/opt/cowrie/configs/cowrie.cfg" ]; then
  cp -f /opt/cowrie/configs/cowrie.cfg "${COWRIE_HOME}/cowrie/etc/cowrie.cfg"
else
  cat > "${COWRIE_HOME}/cowrie/etc/cowrie.cfg" <<EOF
[honeypot]
hostname = honeypot
listen_port = ${COWRIE_PORT_SSH}
telnet_port = ${COWRIE_PORT_TELNET}

[output_cowrie]
enabled = true

[output_jsonlog]
enabled = true
logfile = var/log/cowrie.json
EOF
fi

if [ -f "/opt/cowrie/configs/logging.yaml" ]; then
  cp -f /opt/cowrie/configs/logging.yaml "${COWRIE_HOME}/cowrie/etc/logging.yaml"
else
  cat > "${COWRIE_HOME}/cowrie/etc/logging.yaml" <<'EOF'
version: 1
disable_existing_loggers: False
formatters:
  default:
    format: "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
handlers:
  file:
    class: logging.handlers.RotatingFileHandler
    filename: var/log/cowrie.log
    maxBytes: 10485760
    backupCount: 3
    formatter: default
  json:
    class: logging.FileHandler
    filename: var/log/cowrie.json
    formatter: default
root:
  level: INFO
  handlers: [file, json]
EOF
fi

chown -R ${COWRIE_USER}:${COWRIE_USER} "${COWRIE_HOME}/cowrie"

# CloudWatch Agent install
yum install -y amazon-cloudwatch-agent || {
  curl -s -L -o /tmp/amazon-cloudwatch-agent.rpm "https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
  rpm -Uvh /tmp/amazon-cloudwatch-agent.rpm || true
}

# CloudWatch config
if [ -f "/opt/cowrie/configs/cloudwatch-agent.json" ]; then
  cp -f /opt/cowrie/configs/cloudwatch-agent.json "${CLOUDWATCH_AGENT_CONFIG}"
else
  cat > "${CLOUDWATCH_AGENT_CONFIG}" <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "${COWRIE_HOME}/cowrie/var/log/cowrie.log",
            "log_group_name": "${LOG_GROUP}",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "${COWRIE_HOME}/cowrie/var/log/cowrie.json",
            "log_group_name": "${LOG_GROUP}",
            "log_stream_name": "{instance_id}-json",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF
fi
chown ${COWRIE_USER}:${COWRIE_USER} "${CLOUDWATCH_AGENT_CONFIG}"

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop || true
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:${CLOUDWATCH_AGENT_CONFIG} -s || true

# systemd unit for Cowrie
cat > /etc/systemd/system/cowrie.service <<'UNIT'
[Unit]
Description=Cowrie Honeypot
After=network.target

[Service]
Type=forking
User=cowrie
Group=cowrie
WorkingDirectory=/opt/cowrie/cowrie
ExecStart=/opt/cowrie/venv/bin/python /opt/cowrie/cowrie/bin/cowrie start
ExecStop=/opt/cowrie/venv/bin/python /opt/cowrie/cowrie/bin/cowrie stop
Restart=on-failure
TimeoutSec=30

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable cowrie.service
systemctl start cowrie.service || echo "Cowrie failed to start, check logs."

# Firewalld (if present) — open ports
if command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --permanent --add-port=${COWRIE_PORT_SSH}/tcp || true
  firewall-cmd --permanent --add-port=${COWRIE_PORT_TELNET}/tcp || true
  firewall-cmd --reload || true
fi

echo "Completed Cowrie userdata at $(date -u)"
