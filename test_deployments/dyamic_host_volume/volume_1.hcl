namespace = "default"
name      = "example_volume[0]"
type      = "host"

# mkdir is the default built-in plugin
plugin_id = "mkdir"

constraint {
  attribute = "${attr.unique.hostname}"
  value     = "worker-01"
}
# allows mounting by only one allocation at a time
#capability {
#  access_mode     = "single-node-single-writer"
#  attachment_mode = "file-system"
#}
