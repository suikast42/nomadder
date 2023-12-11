
id        = "assan_volume"
name      = "assan_volume"
type      = "csi"
plugin_id = "dev-volume-plugin"

capacity_min = "1MB"
capacity_max = "10GB"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}