
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
  default = "fabiolb/fabio:1.6.1"
}

job "ingress" {
  datacenters = ["nomadder1"]
  type = "system"

  group "fabio" {
    network {
      mode = "bridge"
      port "http" {
        static = var.ingress_http
        to=9999
      }
      port "https" {
        static = var.ingress_https
        to=9999
      }
      port "ui" {
        static = 9998
        to = 9998
        host_network="private"
      }
    }

    task "fabio" {
      driver = "docker"
      config {
        image = var.image
        network_mode = "host"
        ports = ["http","https","ui"]
        args  = [
          #            "--registry.consul.token=e95b599e-166e-7d80-08ad-aee76e7ddf19",
          #           "--registry.consul.addr=10.21.21.41:8500",
          "--log.access.format=combined",
          "--log.routes.format=all",
          "--log.level=DEBUG",
        ]
      }
      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
