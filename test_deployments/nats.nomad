variable tls_san {
  type        = string
  description = "The cluster domain"
  default     = "cloud.private"
}


variable registry_proxy {
  type        = string
  description = "The cluster registry proxy"
  default     = "registry.cloud.private"
}


variable registry {
  type        = string
  description = "The cluster registry proxy namespace for bi image builds"
  default     = "registry.cloud.private/amovabi"
}





variable version_nats {
  type        = string
  description = "Version of nats server"
  default     = "2.12.0"
}

variable version_nats_exporter {
  type        = string
  description = "Version bi nats prometheus exporter"
  default     = "0.17.3"
}

variable environment {
  type        = string
  description = "Environment of the deployment like dev or production"
  default     = "dev"
}

variable organisation {
  type        = string
  description = "Project org  name"
  default     = "amova"
}


job nats_test {
  type     = "service"
  priority = 80
  #TODO: implement with namespace
  #  namespace = "bi"
  reschedule {
    delay          = "10s"
    delay_function = "constant"
    unlimited      = true
  }
  update {
    max_parallel      = 1
    health_check = "checks"
    # Alloc is marked as unhealthy after this time
    healthy_deadline  = "5m"
    auto_revert = true
    # Mark the task as healthy after 10s positive check
    min_healthy_time = "10s"
    # Task is dead after failed checks in 1h
    progress_deadline = "1h"
  }


  group "nats_task" {

    restart {
      attempts = 1
      interval = "1h"
      delay    = "5s"
      mode     = "fail"
    }
    update {
      max_parallel = 1
    }


    count = 1
    network {
      mode = "bridge"
      port "client" {
        to = 4222
        # For testing
        static = 30020
      }
      port "http" {
        to = 8222
      }
      port "cluster" {
        to = 6222
      }
      port "prometheus-exporter" {
        to = 7777
      }

    }
    service {
      port = "client"
      name = "nats-test"
      tags = [
        # Do not enable    "prometheus", here. The metrics collected over  prometheus-exporter
        "prometheus:server_id=nats-test",
        "prometheus:version=${var.version_nats}",
      ]
      check {
        type     = "http"
        port     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit           = 3
          grace           = "5m"
          ignore_warnings = false
        }
      }
    }



    task "nats-test-prometheus-exporter" {
      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
      service {
        port = "prometheus-exporter"
        # Change the service selector in grafana agent config as well if you cange this name
        name = "nats-test-exporter"
        tags = [
          "prometheus",
          "prometheus:server_id=${NOMAD_ALLOC_NAME}",
          "prometheus:version=${var.version_nats}",
          "prometheus:exporter_id=${NOMAD_TASK_NAME}",
          "prometheus:version_exporter=${var.version_nats_exporter}",
          "prometheus:environment=${var.environment}",
          "prometheus:organisation=${var.tls_san}",
        ]
        check {
          type     = "http"
          port     = "prometheus-exporter"
          path     = "/metrics"
          interval = "5s"
          timeout  = "2s"
          check_restart {
            limit           = 3
            grace           = "60s"
            ignore_warnings = false
          }
        }
      }
      driver = "docker"
      config {
        image = "${var.registry_proxy}/natsio/prometheus-nats-exporter:${var.version_nats_exporter}"
        labels = {
          "com.github.logunifier.application.name"        = "${NOMAD_ALLOC_NAME}"
          "com.github.logunifier.application.version"     = "${var.version_nats_exporter}"
          "com.github.logunifier.application.org"         = "${var.organisation}"
          "com.github.logunifier.application.env"         = "${var.environment}"
          "com.github.logunifier.application.pattern.key" = "tslevelmsg"
        }
        ports = ["prometheus_exporter"]
        args = [
          "-accstatz",
          "-connz_detailed",
          "-gatewayz",
          "-healthz",
          "-jsz=all",
          "-leafz",
          "-subz",
          "-routez",
          "-varz",
          "-use_internal_server_name",
          "http://localhost:${NOMAD_PORT_http}"
        ]
      }
    }

    task "nats" {


      driver = "docker"
      config {
        image = "${var.registry_proxy}/nats:${var.version_nats}-alpine"
        labels = {
          "com.github.logunifier.application.name"        = "${NOMAD_ALLOC_NAME}"
          "com.github.logunifier.application.version"     = "${var.version_nats}"
          "com.github.logunifier.application.org"         = "${var.organisation}"
          "com.github.logunifier.application.env"         = "${var.environment}"
          "com.github.logunifier.application.pattern.key" = "tslevelmsg"
        }
        ports = ["client", "http", "cluster"]
        args = [
          "-c", "/config/nats.conf",
          "-js",
          #       "-DV"
        ]
        volumes = [
          "local/nats.conf:/config/nats.conf",
          "local/mappings.conf:/config/mappings.conf",
        ]
      }
      resources {
        cpu        = 500
        memory     = 512
        memory_max = 32768
      }
      template {
        destination     = "local/nats.conf"
        change_mode     = "restart"
        right_delimiter = "++"
        left_delimiter  = "++"
        data            = <<EOF
# Client port of ++ env "NOMAD_PORT_client" ++ on all interfaces
port: ++ env "NOMAD_PORT_client" ++

# HTTP monitoring port
monitor_port: ++ env "NOMAD_PORT_http" ++
server_name: "++ env "NOMAD_ALLOC_NAME" ++"
#If true enable protocol trace log messages. Excludes the system account.
trace: false
#If true enable protocol trace log messages. Includes the system account.
trace_verbose: false
#if true enable debug log messages
debug: false
http_port: ++ env "NOMAD_PORT_http" ++
#http: nats.service.consul:++ env "NOMAD_PORT_http" ++

system_account: SYS

accounts: {
   SYS: {
   users: [
     {user:sys, password:natsadmin}
    ]
   }
}
#authorization: {
#  default_permissions {
#    pub = [">"]
#    sub = [">"]
#  }
#}

jetstream: enabled
jetstream {
  store_dir: /data/jetstream

  # 1GB
  max_memory_store: 2G

  # 10GB
  max_file_store: 10G
}

include mappings.conf

              EOF
      }

      template {
        destination     = "local/mappings.conf"
        change_mode     = "restart"
        right_delimiter = "++"
        left_delimiter  = "++"
        data            = <<EOF
mappings = {

  # Simple direct mapping.  Messages published to foo are mapped to bar.
  #foo: bar

  # remapping tokens can be done with $<N> representing token position.
  # In this example bar.a.b would be mapped to baz.b.a.
  # bar.*.*: baz.$2.$1

  # You can scope mappings to a particular cluster
  # foo.cluster.scoped : [
  #   { destination: bar.cluster.scoped, weight:100%, cluster: us-west-1 }
  # ]

  # Use weighted mapping for canary testing or A/B testing.  Change dynamically
  # at any time with a server reload.
  # myservice.request: [
  #   { destination: myservice.request.v1, weight: 90% },
  #   { destination: myservice.request.v2, weight: 10% }
  # ]

  # A testing example of wildcard mapping balanced across two subjects.
  # 20% of the traffic is mapped to a service in QA coded to fail.
 # myservice.test.*: [
 #   { destination: myservice.test.$1, weight: 80% },
 #   { destination: myservice.test.fail.$1, weight: 20% }
 # ]

  # A chaos testing trick that introduces 50% artificial message loss of
  # messages published to foo.loss
  #foo.loss.>: [ { destination: foo.loss.>, weight: 50% } ]

  #escaping jinja curly braces
  #devices.*: devices.{{ '{{' }}wildcard(1){{ '}}' }}.{{ '{{' }}partition(10,1){{ '}}' }}
  #  Native nats deterministic partitining is deisbaled because of dairnes issues. See eu.amova.bi.services.eventlog.impl.grpc.PartitionService
  #  ingress.eventlog.*: "ingress.eventlog.{{partition(10,1)}}.{{wildcard(1)}}"
  #  ingress.devicetracking.*: "ingress.devicetracking.{{partition(10,1)}}.{{wildcard(1)}}"
  #  ingress.iotsensor.*.*: "ingress.iotsensor.{{partition(10,1,2)}}.{{wildcard(1)}}.{{wildcard(2)}}"
  #  ingress.wmsstatistics.*: "ingress.wmsstatistics.{{partition(10,1)}}.{{wildcard(1)}}"
}
              EOF
      }
    }
  }
}

