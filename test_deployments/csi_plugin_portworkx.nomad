## This setup not works currently
# Portworx needs an unformatted and unmounted block device that it can fully manage.
# The ubuntu base image is nor prepared for that.
# For adding disk see flags -a -A or -s in cmd flags. See https://docs.portworx.com/shared/install-with-other-docker-cmdargs/
job "portworx" {
  type        = "service"
  datacenters = ["nomadder1"]

  group "portworx" {
    count = 1

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

    # restart policy for failed portworx tasks
    restart {
      attempts = 3
      delay    = "30s"
      interval = "5m"
      mode     = "fail"
    }

    # how to handle upgrades of portworx instances
    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
      auto_revert      = true
      canary           = 0
      stagger          = "30s"
    }

    network {
      port "portworx" {
        static = "9015"
        to = "9015"
      }
    }

    task "px-node" {
      driver = "docker"
      kill_timeout = "120s"   # allow portworx 2 min to gracefully shut down
      kill_signal = "SIGTERM" # use SIGTERM to shut down the nodes

      # consul service check for portworx instances
      service {
        name = "px-node"
        check {
          port     = "portworx"
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
          check_restart {
            limit = 3
            grace = "60s"
            ignore_warnings = false
          }
        }
      }
      # setup environment variables for px-nodes
      env {
        AUTO_NODE_RECOVERY_TIMEOUT_IN_SECS = "1500"
        PX_TEMPLATE_VERSION                = "V4"
        CSI_ENDPOINT                       = "unix://var/lib/csi/csi.sock"
      }

      # CSI Driver config
      csi_plugin {
        id                     = "portworx"
        type                   = "monolith"
        mount_dir              = "/opt/nomadvolumes/csi"
        health_timeout         = "30m"                  # Nomad 1.3.2 and later only
        stage_publish_base_dir = "/opt/nomadvolumes/csi/publish" # Nomad 1.3.4 and later only
      }

      # container config
      config {
        image        = "portworx/oci-monitor:2.13.1"
        network_mode = "host"
        ipc_mode = "host"
        privileged = true

        # configure your parameters below
        # do not remove the last parameter (needed for health check)
        args = [
          "-c", "px-cluster-nomadv1",
          "-a",
          "-b",
          "-k", "consul:https://172.42.21.20:8501",
          "-ca","/certs/ca/cluster-ca-bundle.pem",
          "-cert", "/certs/consul/consul.pem",
          "-key", "/certs/consul/consul-key.pem",
          "--endpoint", "0.0.0.0:9015"
        ]

        volumes = [
          "/var/cores:/var/cores",
          "/var/run/docker.sock:/var/run/docker.sock",
          "/run/containerd:/run/containerd",
          "/etc/pwx:/etc/pwx",
          "/opt/pwx:/opt/pwx",
          "/proc:/host_proc",
          "/etc/systemd/system:/etc/systemd/system",
          "/var/run/log:/var/run/log",
          "/var/log:/var/log",
          "/var/run/dbus:/var/run/dbus",
          "/usr/local/share/ca-certificates/cloudlocal/:/certs/ca",
          "/etc/opt/certs/consul//:/certs/consul"
        ]

      }

      # resource config
      resources {
        cpu    = 1024
        memory = 2048
      }

    }
  }
}