job "blackbox-exporter" {
  datacenters = ["nomadder1"]
  type        = "service"

  group "blackbox-group" {
    count = 1
    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
    }
    volume "cert_consul" {
      type      = "host"
      source    = "cert_consul"
      read_only = true
    }
    network {
      mode = "bridge"
      port "http" {
        to = 9115
      }
    }
    task "blackbox-task" {
      driver = "docker"
      volume_mount {
      # OS certifate folders
      #  "/etc/ssl/certs/ca-certificates.crt",              // Debian/Ubuntu/Gentoo etc.
      #"/etc/pki/tls/certs/ca-bundle.crt",                  // Fedora/RHEL 6
      #"/etc/ssl/ca-bundle.pem",                            // OpenSUSE
      #"/etc/pki/tls/cacert.pem",                           // OpenELEC
      #"/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem", // CentOS/RHEL 7
      #"/etc/ssl/cert.pem",                                 // Alpine Linux
        volume      = "ca_cert"
        # the server searches in the /CAs path at that specified directory.
        # Do not change the sub folder name CAs
        destination = "/etc/opt/certs/ca"
      }
      volume_mount {
        volume      = "cert_consul"
        destination = "/etc/opt/certs/client"
      }
      config {
        image = "prom/blackbox-exporter:v0.24.0"
        ports = ["http"]
        args = ["--config.file","/config/blackbox.yaml"]
        volumes = [
          "local/blackbox.yaml:/config/blackbox.yaml",
        ]
      }
#Default config from https://raw.githubusercontent.com/prometheus/blackbox_exporter/master/blackbox.yml
#Example config https://github.com/prometheus/blackbox_exporter/blob/master/example.yml
# http_integrations module is for validating that the grafana agents scrapping config
# all the listed integrations must exists
      template {
        right_delimiter = "++"
        left_delimiter = "++"
        data = <<EOF
modules:
  http_integrations:
    prober: http
    http:
      preferred_ip_protocol: "ip4"
      # Probe fails if response body does not match regex.
      fail_if_body_not_matches_regexp:
        - '.*integration/agent.*'
        - '.*integration/consul_exporter.*'
        - '.*integration/node_exporter.*'
        - '.*integration/nomad.*'
      tls_config:
        ca_file: "/etc/opt/certs/ca/cluster-ca-bundle.pem"
        cert_file: "/etc/opt/certs/client/consul.pem"
        key_file: "/etc/opt/certs/client/consul-key.pem"
        insecure_skip_verify: true
              EOF
        destination = "local/blackbox.yaml"
      }


      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "blackbox-exporter"
        port = "http"
#        tags = [
#          "traefik.enable=true",
#          "traefik.consulcatalog.connect=false",
#          "traefik.http.routers.blackbox.tls=true",
#          "traefik.http.routers.blackbox.rule=Host(`blackbox.cloud.private`)",
#        ]
        check {
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
          check_restart {
            limit = 3
            grace = "30s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
