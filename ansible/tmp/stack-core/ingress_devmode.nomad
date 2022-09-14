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
#    volume "cert_ingress" {
#      type      = "host"
#      source    = "cert_ingress"
#      read_only   = true
#    }
#    volume "ca_cert" {
#      type      = "host"
#      source    = "ca_cert"
#      read_only   = true
#    }

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


    task "traefik" {
      driver = "docker"
      service {
        name = "traefik"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.traefik.rule=Host(`cloud.private`) && (PathPrefix(`/ingress`) || PathPrefix(`/api`))",

          #### set traefik dashboard
          "traefik.http.routers.traefik.service=api@internal",

          #### set middlewares: stripprefix for dashboard
          "traefik.http.routers.traefik.middlewares=traefik-strip",
          "traefik.http.middlewares.traefik-strip.stripprefix.prefixes=/ingress",

          #### set TLS
          "traefik.http.routers.traefik.tls=true"
        ]
        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
#      volume_mount {
#        volume      = "cert_ingress"
#        destination = "/etc/opt/certs/ingress"
#      }
#      volume_mount {
#        volume      = "ca_cert"
#        destination = "/etc/opt/certs/ca"
#      }

      config {
        image        = var.image
        network_mode = "host"
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "local/certconfig.toml:/etc/traefik/certconfig.toml"
        ]
      }
#      template {
#        data = <<EOF
#[serversTransport]
#  insecureSkipVerify = false
#  rootCAs = ["/etc/opt/certs/ca/ca.crt","/etc/opt/certs/ca/cluster-ca.crt"]
#
#[tls.options]
#  [tls.options.default]
#    [tls.options.default.clientAuth]
#      caFiles = ["/etc/opt/certs/ca/ca.crt","/etc/opt/certs/ca/cluster-ca.crt"]
#      clientAuthType = "NoClientCert"
##      clientAuthType = "RequireAndVerifyClientCert"
#   #   clientAuthType = "RequireAnyClientCert"
#
#[tls.stores]
#  [tls.stores.default]
#    [tls.stores.default.defaultCertificate]
#      certFile = "/etc/opt/certs/ingress/nomad-ingress.pem"
#      keyFile = "/etc/opt/certs/ingress/nomad-ingress-key.pem"
#
#        EOF
#        destination = "local/certconfig.toml"
#      }
      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":80"
#    [entryPoints.http.http.redirections]
#      [entryPoints.http.http.redirections.entryPoint]
#        to = "https"
#        scheme = "https"
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
    debug = false
#[providers]
#  [providers.file]
#    filename = "/etc/traefik/certconfig.toml"

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false
    connectAware = true
    connectByDefault = false

  [providers.consulCatalog.endpoint]
      address = "10.21.21.41:8500"
      scheme  = "http"
#      address = "127.0.0.1:8501"
#      scheme  = "https"
#      token = "e95b599e-166e-7d80-08ad-aee76e7ddf19"


#[providers.consulCatalog.endpoint.tls]
#  ca = "/etc/opt/certs/ca/cluster-ca.crt"
#  cert = "/etc/opt/certs/ingress/nomad-ingress.pem"
#  key = "/etc/opt/certs/ingress/nomad-ingress-key.pem"


[log]
  level = "DEBUG"

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
