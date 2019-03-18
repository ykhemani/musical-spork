job "nginx" {
  datacenters = ["us-east-1a","us-east-1b","us-east-1c"]
  type = "service"

  group "nginx" {
    count = 3

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        port_map {
          http = 80
        }
        port_map {
          https = 443
        }
        volumes = [
          "conf/default.conf:/etc/nginx/conf.d/default.conf",
          "secret/vault_kv.crt:/etc/nginx/ssl/vault_kv.crt",
          "secret/vault_kv.key:/etc/nginx/ssl/vault_kv.key",
          "secret/vault_pki.key:/etc/nginx/ssl/vault_pki.key",
        ]
      }

      template {
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<EOH
{{ range $i1, $service := services }}
{{ range $i2, $tag := $service.Tags }}
{{ if $tag | regexMatch "urlprefix-" }}
{{ $urlprefix := $tag | regexReplaceAll ".*urlprefix-/(\\S*).*" "$1" }}
upstream {{ $urlprefix }} {
    {{ range service $service.Name }}
    {{ if .Tags | contains $tag }}
    server {{ .Address }}:{{ .Port }};
    {{ end }}
    {{ end }}
}
{{ end  }}
{{ end  }}
{{ end  }}

server {
  listen 80 default_server;
  listen [::]:80 default_server;

  location / {
    return 301 https://$host$request_uri;
  }
}

server {
  listen 443 ssl default_server;
  listen [::]:443 ssl;

  {{ if key "demo/vault_pki" | parseBool }}
  ssl_certificate /etc/nginx/ssl/vault_pki.key;
  ssl_certificate_key /etc/nginx/ssl/vault_pki.key;
  {{ else }}
  ssl_certificate /etc/nginx/ssl/vault_kv.crt;
  ssl_certificate_key /etc/nginx/ssl/vault_kv.key;
  {{ end }}

  {{ range $i1, $service := services }}
  {{ range $i2, $tag := $service.Tags }}
  {{ if $tag | regexMatch "urlprefix-" }}
  {{ $urlprefix := $tag | regexReplaceAll ".*urlprefix-/(\\S*).*" "$1" }}
  location /{{ $urlprefix }} {
    client_max_body_size 0;
    proxy_connect_timeout 300;
    proxy_http_version 1.1;
    proxy_pass http://{{ $urlprefix }}/;
    proxy_read_timeout 300;
    proxy_redirect http:// https://;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
  }
  {{ end }}
  {{ end }}
  {{ end }}
}
        EOH
        destination = "conf/default.conf"
      }

      template {
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<EOH
{{ with secret "kv/nginx-pki" }}
{{ .Data.pub}}
{{ end }}
      EOH

        destination = "secret/vault_kv.crt"
      }

      template {
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<EOH
{{ with secret "kv/nginx-pki" }}
{{ .Data.prv }}
{{ end }}
      EOH

        destination = "secret/vault_kv.key"
      }

      template {
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<EOH
{{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=30m" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
      EOH

        destination = "secret/vault_pki.key"
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port "http" {
            static = 80
          }
          port "https" {
            static = 443
          }
        }
      }

      service {
        name = "nginx"
        tags = [ "frontend" ]
        port = "https"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      vault {
        policies = ["kv-nginx", "pki"]
      }
    }
  }
}
