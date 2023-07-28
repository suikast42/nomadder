variable "image_tag" {
  type = string
}

job "elasticsearch" {
  datacenters = ["es1"]
  type = "service"

  migrate {
    health_check     = "checks"
    healthy_deadline = "3m"
    max_parallel     = 1
    min_healthy_time = "5s"
  }

  update {
    health_check     = "checks"
    auto_revert      = true
    healthy_deadline = "3m"
    max_parallel     = 1
    min_healthy_time = "5s"
  }

  group "master" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    spread {
      attribute = "$${attr.platform.aws.placement.availability-zone}"
    }

    network {
      port "http" { }
      port "transport" { }
    }

    volume "master" {
      type            = "csi"
      source          = "elasticsearch_master"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      per_alloc       = true

      mount_options {
        fs_type     = "ext4"
      }
    }

    task "elasticsearch_master_init" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"
      config {
        image   = "${ account_id }.dkr.ecr.${ region }.amazonaws.com/${ env }-elasticsearch:$${ var.image_tag }"
        command = "chown"
        args = ["-R", "1000:1000", "/usr/share/elasticsearch/data"]
      }

      volume_mount {
        volume      = "master"
        destination = "/usr/share/elasticsearch/data"
      }

      resources {
        cpu = 250
        memory = 250
        # cpu = 500
        # memory = 2048
      }
    }

    task "elasticsearch_master" {
      driver = "docker"

      config {
        # image = "nginx:latest"
        # auth {
        #   server_address = "http://www.dockerhub.com"
        # }

        image = "535528833958.dkr.ecr.us-west-2.amazonaws.com/ninja-elasticsearch:7.10.2"
        ports = ["http", "transport"]
        args = [
          "elasticsearch",
          "-Ecluster.initial_master_nodes=elasticsearch-master-0,elasticsearch-master-1,elasticsearch-master-2",
          "-Ecluster.name=my-es-cluster",
          "-Enode.name=elasticsearch-master-$${NOMAD_ALLOC_INDEX}",
          "-Enode.roles=master",
          "-Ediscovery.seed_providers=file",
          "-Enetwork.host=0.0.0.0",
          "-Enetwork.publish_host=$${NOMAD_IP_http}",
          "-Ehttp.publish_port=$${NOMAD_HOST_PORT_http}",
          "-Ehttp.port=$${NOMAD_PORT_http}",
          "-Etransport.publish_port=$${NOMAD_HOST_PORT_transport}",
          "-Etransport.tcp.port=$${NOMAD_PORT_transport}",
        ]
      }

      volume_mount {
        volume      = "master"
        destination = "/usr/share/elasticsearch/data/"
      }

      resources {
        cpu = 1500
        memory = 1500
        # cpu = 500
        # memory = 2048
      }
      template {
        data = <<EOF
{{- range service "elasticsearch-master" -}}
{{ .Address }}:{{ .Port }}
{{ end }}
EOF
        destination = "local/unicast_hosts.txt"
        change_mode = "noop"
      }

      service {
        name = "elasticsearch-master"
        port = "transport"

        check {
          type = "tcp"
          port = "transport"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
  }
  group "data" {
    count = 3

    spread {
      attribute = "$${attr.platform.aws.placement.availability-zone}"
    }

    network {
      port "http" {
        static = 9200
      }
      port "transport" { }
    }

    volume "data" {
      type            = "csi"
      source          = "elasticsearch_data"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      per_alloc       = true

      mount_options {
        fs_type     = "ext4"
      }
    }

    task "elasticsearch_data_init" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"
      config {
        image = "535528833958.dkr.ecr.us-west-2.amazonaws.com/ninja-elasticsearch:7.10.2"
        command = "chown"
        args = ["-R", "1000:1000", "/usr/share/elasticsearch/data"]

      }

      volume_mount {
        volume      = "data"
        destination = "/usr/share/elasticsearch/data"
      }

      resources {
        cpu = 500
        memory = 128
      }
    }

    task "elasticsearch" {
      driver = "docker"

      # constraint {
      #   distinct_hosts = true
      # }

      config {
        # image = "nginx:latest"
        # auth {
        #   server_address = "http://www.dockerhub.com"
        # }
        image = "535528833958.dkr.ecr.us-west-2.amazonaws.com/ninja-elasticsearch:7.10.2"
        ports = ["http", "transport"]
        # TODO: initial_master_nodes should be removed after the initial bootstrap
        args = [
          "elasticsearch",
          "-Ecluster.initial_master_nodes=elasticsearch-master-0,elasticsearch-master-1,elasticsearch-master-2",
          "-Ecluster.name=my-es-cluster",
          "-Enode.name=elasticsearch-data-$${NOMAD_ALLOC_INDEX}",
          "-Enode.roles=data",
          "-Ediscovery.seed_providers=file",
          "-Enetwork.host=0.0.0.0",
          "-Enetwork.publish_host=$${NOMAD_IP_http}",
          "-Ehttp.publish_port=$${NOMAD_HOST_PORT_http}",
          "-Ehttp.port=$${NOMAD_PORT_http}",
          "-Etransport.publish_port=$${NOMAD_HOST_PORT_transport}",
          "-Etransport.tcp.port=$${NOMAD_PORT_transport}",
        ]
      }

      volume_mount {
        volume      = "data"
        destination = "/usr/share/elasticsearch/data"
      }

      resources {
        cpu = 1500
        memory = 1500
      }

      template {
        data = <<EOF
{{- range service "elasticsearch-master" -}}
{{ .Address }}:{{ .Port }}
{{ end }}
EOF
        destination = "local/unicast_hosts.txt"
        change_mode = "noop"
      }

      service {
        name = "elasticsearch-data"
        port = "transport"

        check {
          type = "tcp"
          port = "transport"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
  }
}
