#NOMAD_NAMESPACE
#NOMAD_JOB_NAME
#NOMAD_TASK_NAME
#NOMAD_GROUP_NAME
job "whoami" {

  namespace = "test1"
  group "whoami" {
    count = 1

    network {
      mode = "bridge"
      port "web" {
      }
    }

    service {
      name = "${NOMAD_NAMESPACE}-${NOMAD_GROUP_NAME}"
      port = "web"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.${NOMAD_GROUP_NAME}-${NOMAD_ALLOC_ID}.rule=Host(`${NOMAD_NAMESPACE}.${NOMAD_GROUP_NAME}.cloud.private`)",
        "traefik.http.routers.${NOMAD_GROUP_NAME}-${NOMAD_ALLOC_ID}.tls=true",
      ]

      check {
        type     = "http"
        path     = "/health"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "whoami" {
      driver = "docker"
#      driver = "containerd-driver"
      config {
        image = "traefik/whoami"
        ports = ["web"]
        args  = ["--port", "${NOMAD_PORT_web}"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}