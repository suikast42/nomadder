#region var definitions
variable "datacenter" {
  type = string
  description = "Deploy to this datacenter"
  default = "nomadder1"
}

variable "ingress_http" {
  type = number
  description = "Ingress http port"
  default = 80
}

variable "ingress_https" {
  type = number
  description = "Ingress https port"
  default = 443
}

variable "image" {
  type = string
  description = "Default image"
  default = "traefik:v2.8.4"
}
# endregion

job "ingress" {
  datacenters = [var.datacenter]
  type        = "service"

  group "traefik" {

    network {
      port "http" {
        static = var.ingress_http
      }
      port "https" {
        static = var.ingress_https
      }
      port "ui" {
        static = 8081
      }
    }

    service {
      name = "traefik"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = var.image
        network_mode = "host"
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.http.http.redirections]
      [entryPoints.http.http.redirections.entryPoint]
        to = "https"
        scheme = "https"
    [entryPoints.https]
    address = ":443"
    [entryPoints.traefik]
    address = ":8081"
# TCP / UDP over one port
#  [entryPoints.tcpep]
#    address = ":3179"
#  [entryPoints.udpep]
#    address = ":3179/udp"
[api]
    dashboard = true
    insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false
    connectAware = true
    connectByDefault = false

  [providers.consulCatalog.endpoint]
      address = "127.0.0.1:8500"
      scheme  = "http"
#      token = "ee443d4a-d143-b46e-998e-535fca00fb00"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
