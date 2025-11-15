# Deployment Guide

This document covers deployment strategies for METALlama.cpp in various environments.

## Local Deployment

### Standard Installation
```bash
# Single user deployment
./install-metallama.sh --user

# System-wide deployment
sudo ./install-metallama.sh --system

# Secure deployment (localhost only)
./install-metallama.sh --secure
```

### Service Configuration
```bash
# Production configuration
~/llama-service.sh configure --mode production

# Development configuration
~/llama-service.sh configure --mode development

# Custom configuration
~/llama-service.sh configure --config /path/to/config.json
```

## Network Deployment

### Local Network Access
```bash
# Enable network access
./install-metallama.sh --host 0.0.0.0 --port 8080

# Custom port
./install-metallama.sh --host 192.168.1.100 --port 8081

# Multiple instances
./install-metallama.sh --port 8080 --instance main
./install-metallama.sh --port 8081 --instance secondary
```

### Security Configuration
```bash
# Authentication enabled
./install-metallama.sh --auth-token "your-secure-token"

# SSL/TLS setup
./install-metallama.sh --ssl-cert /path/to/cert.pem --ssl-key /path/to/key.pem

# Firewall rules
sudo pfctl -f /etc/pf.conf.llama
```

## Docker Deployment

### Dockerfile
```dockerfile
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget

# Install conda
RUN wget -qO- https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b /opt/conda \
    && rm Miniconda3-latest-Linux-x86_64.sh

# Set environment
ENV PATH="/opt/conda/bin:$PATH"
ENV CONDA_DEFAULT_ENV=metallama

# Clone and build
WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git \
    && cd llama.cpp \
    && cmake -B build -DLLAMA_METAL=OFF -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release

# Copy application
COPY . /app/metallama
RUN chmod +x /app/metallama/*.sh

# Expose port
EXPOSE 8080

# Run script
CMD ["/app/metallama/run-server.sh"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  metallama:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./models:/app/models
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - LLAMA_MODEL_PATH=/app/models
      - LLAMA_CONFIG_PATH=/app/config
      - LLAMA_LOG_PATH=/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Cloud Deployment

### AWS EC2 (macOS)
```bash
# Launch macOS EC2 instance
aws ec2 run-instances \
    --image-id ami-01234567890abcdef0 \
    --instance-type mac1.metal \
    --key-name my-key-pair \
    --security-group-ids sg-01234567890abcdef0 \
    --subnet-id subnet-01234567890abcdef0

# Deploy via user data
aws ec2 run-instances \
    --user-data file://install-metallama.sh \
    ...other-parameters...
```

### Google Cloud Platform
```bash
# Create macOS VM
gcloud compute instances create metallama-server \
    --image-family macos-ventura \
    --image-project macos-cloud \
    --machine-type n1-standard-4 \
    --zone us-central1-a \
    --metadata-from-file startup-script=install-metallama.sh
```

## Reverse Proxy Deployment

### Nginx Configuration
```nginx
# /etc/nginx/sites-available/metallama
server {
    listen 80;
    server_name ai.example.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ai.example.com;
    
    # SSL certificates
    ssl_certificate /etc/ssl/certs/ai.example.com.crt;
    ssl_certificate_key /etc/ssl/private/ai.example.com.key;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Proxy to METALlama
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        access_log off;
    }
}
```

### Apache Configuration
```apache
# /etc/apache2/sites-available/metallama.conf
<VirtualHost *:80>
    ServerName ai.example.com
    Redirect permanent / https://ai.example.com/
</VirtualHost>

<VirtualHost *:443>
    ServerName ai.example.com
    
    # SSL configuration
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/ai.example.com.crt
    SSLCertificateKeyFile /etc/ssl/private/ai.example.com.key
    
    # Security headers
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    Header always set X-XSS-Protection "1; mode=block"
    
    # Proxy configuration
    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
    
    # WebSocket support
    ProxyPass /ws ws://127.0.0.1:8080/ws
    ProxyPassReverse /ws ws://127.0.0.1:8080/ws
</VirtualHost>
```

## Load Balancing

### HAProxy Configuration
```haproxy
global
    daemon
    maxconn 4096

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend metallama_frontend
    bind *:80
    default_backend metallama_servers

backend metallama_servers
    balance roundrobin
    option httpchk GET /health
    server metallama1 127.0.0.1:8080 check
    server metallama2 127.0.0.1:8081 check
    server metallama3 127.0.0.1:8082 check
```

## Monitoring and Logging

### Prometheus Integration
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'metallama'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 5s
```

### Grafana Dashboard
```json
{
  "dashboard": {
    "title": "METALlama Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": ["rate(requests_total[5m])"]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": ["histogram_quantile(0.95, rate(request_duration_seconds_bucket[5m]))"]
      },
      {
        "title": "GPU Utilization",
        "type": "graph",
        "targets": ["gpu_utilization_percent"]
      }
    ]
  }
}
```

## Production Best Practices

### Security
```bash
# Network security
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw deny 8080/tcp  # Direct access blocked

# Authentication
export LLAMA_API_KEY="$(openssl rand -hex 32)"
export LLAMA_REQUIRE_AUTH=true

# Rate limiting
nginx -c nginx.conf -g 'worker_processes auto; worker_rlimit_nofile 65535;'
```

### Performance
```bash
# Process management
systemctl enable metallama
systemctl start metallama

# Resource limits
echo "metallama soft nofile 65536" >> /etc/security/limits.conf
echo "metallama hard nofile 65536" >> /etc/security/limits.conf

# Memory optimization
echo 'vm.swappiness=10' >> /etc/sysctl.conf
sysctl -p
```

### Backup and Recovery
```bash
# Automated backup
#!/bin/bash
# backup-metallama.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/metallama/$DATE"

mkdir -p "$BACKUP_DIR"
cp -r ~/.config/llama_mps_server "$BACKUP_DIR/config"
cp -r ~/METALlama.cpp/models "$BACKUP_DIR/models"
cp -r ~/Desktop/llama_server_logs "$BACKUP_DIR/logs"

# Keep last 7 days
find /backup/metallama -type d -mtime +7 -exec rm -rf {} \;
```

## Scaling Strategies

### Horizontal Scaling
```bash
# Multiple instances on different ports
for PORT in 8080 8081 8082 8083; do
    ./install-metallama.sh --port $PORT --instance "worker-$PORT" &
done

# Load balancer configuration
nginx -c nginx-ha.conf
```

### Vertical Scaling
```bash
# Resource allocation
./install-metallama.sh \
    --gpu-layers 48 \
    --context-size 16384 \
    --batch-size 1024 \
    --threads 16
```

## Troubleshooting Deployment

### Common Issues
```bash
# Service not starting
~/llama-service.sh logs
journalctl -u metallama -f

# Network access issues
netstat -tlnp | grep 8080
ss -tlnp | grep 8080

# Performance problems
top -p $(pgrep metallama)
iotop -p $(pgrep metallama)
nvidia-smi  # If applicable
```

This deployment guide provides comprehensive options for running METALlama.cpp in various environments from local development to production cloud deployments.