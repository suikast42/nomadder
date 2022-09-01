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
      port "https" {
        static = 443
        to = 443
      }


    }
    service {
      name = "traefik"
      tags = [
        "traefik",
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=Host(`tdb.cloud.private`)",
        "traefik.http.routers.dashboard.service=api@internal",
        "traefik.http.routers.dashboard.entrypoints=web,websecure",
      ]
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
#        network_mode = "bridge"
        network_mode = "host"
        ports = ["http","https"]
        args  = [
          "--entryPoints.web.address=:80",
          "--entryPoints.websecure.address=:443",
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
          "--providers.consulcatalog.endpoint.address=10.21.21.41:8500",
          "--providers.consulcatalog.endpoint.scheme=http",
        ]
      }
    }
  }
}

