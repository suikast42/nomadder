job "ingress" {
  region      = "global"
  datacenters = ["nomadder_1"]
  type        = "system"


  group "traefik" {
    network {

      port "http" {
        static = 80
        to = 80
      }
      port "http-admin" {
        static = 8081
        to = 8081
      }

    }
    service {
      name = "traefik"
      port = "http"

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
        image = "traefik:v2.8.3"
        network_mode = "host"
        args  = [
          "--entryPoints.http.address=:80",
          "--entryPoints.traefik.address=:8081",
          "--accesslog=true",
          "--api=true",
          "--api.dashboard=true",
          "--api.insecure=true",
          "--metrics=true",
          "--metrics.prometheus=true",
          "--metrics.prometheus.entryPoint=http",
          "--ping=true",
          "--ping.entryPoint=http",
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.exposedByDefault=false",
          "--providers.consulcatalog.endpoint.address=127.0.0.1:8500",
          "--providers.consulcatalog.endpoint.scheme=http",
        ]
      }
    }
  }
}

