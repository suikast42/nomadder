
variable "hostname" {
  type = string
  description = "Place this job on this host"
  default = "worker-02"
}


variable "tls_san" {
  type = string
  description = "The cluster domain"
  default = "cloud.private"
}

job "csi-plugin" {

  constraint {
    attribute    = "${attr.unique.hostname}"
    value = "${var.hostname}"
  }

  group "csi" {
    task "plugin" {
      driver = "docker"

      config {
        image = "registry.${var.tls_san}/k8scsi/hostpathplugin:v1.2.0"

        args = [
          "--drivername=csi-hostpath",
          "--v=5",
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=worker-02",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "dev-volume-plugin"
        type      = "monolith"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}