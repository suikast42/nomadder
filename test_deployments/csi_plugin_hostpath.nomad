job "csi-plugin" {
  type        = "system"
  datacenters = ["nomadder1"]

  group "csi" {

    task "plugin" {
      driver = "docker"

      config {
        image = "registry.cloud.private/k8scsi/hostpathplugin:v1.6.0"
#        image = "quay.io/k8scsi/hostpathplugin:v1.6.0"

        args = [
          "--drivername=csi-hostpath",
          "--v=5",
          "--endpoint=${CSI_ENDPOINT}",
          "--nodeid=node-${NOMAD_ALLOC_INDEX}",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "hostpath-plugin"
        type      = "monolith" #node" # doesn't support Controller RPCs
        mount_dir = "/csi"
        stage_publish_base_dir = "/mnt/cluster/nomadvolumes/csi"
      }

      resources {
        cpu    = 256
        memory = 128
      }
    }
  }
}