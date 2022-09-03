job "traefik" {
  datacenters = ["nomadder1"]

  group "edge" {
    network {
      mode = "bridge"

      port "http" {
        static = 8080
        to = 8080
      }
    }

    service {
      name = "traefik"
      port = 8080
      connect {
        native = true
      }
    }

    task "traefik" {
      driver = "docker"
      config {
        image = "shoenig/traefik:connect" # use the official image when it is ready
        args = [

          "--providers.consulcatalog.connectaware=true",
          "--providers.consulcatalog.connectbydefault=false",
          "--providers.consulcatalog.exposedbydefault=false",
          "--entrypoints.http=true",
          "--entrypoints.http.address=:8080",


          # Automatically configured by Nomad through CONSUL_* environment variables
          # as long as client consul.share_ssl is enabled
          # "--providers.consulcatalog.endpoint.address=<socket|address>"
          # "--providers.consulcatalog.endpoint.tls.ca=<path>"
          # "--providers.consulcatalog.endpoint.tls.cert=<path>"
          # "--providers.consulcatalog.endpoint.tls.key=<path>"
          # "--providers.consulcatalog.endpoint.token=<token>"
          # "--providers.consulcatalog.prefix=traefik",
        ]
      }

      env {
        # Currently required, this ticket will automate setting this variable
        CONSUL_TLS_SERVER_NAME = "localhost"
      }
    }
  }
}