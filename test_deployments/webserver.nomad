job "webserver" {
  datacenters = ["nomadder1"]
  type = "service"

  group "webserver" {
    count = 3

    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
      port "healthcheck" {
        to = -1
      }
    }

    service {
      name = "apache-webserver"
      tags = ["urlprefix-webserver.cloud.private:80","webserver.urlprefix-cloud.private:443"]
      port = "80"
#      check {
#        name     = "alive"
#        type     = "http"
#        path     = "/"
#        interval = "10s"
#        timeout  = "2s"
#      }
      check {
        name     = "apache-webserver-health"
        port     = "healthcheck"
        type     = "http"
        protocol = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "3s"
        expose   = true
      }
      connect {
        sidecar_service {}
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "apache" {
      driver = "docker"
      config {
        image = "httpd:latest"
        ports = ["http"]
      }
    }
  }
}