namespace = "default"
name      = "dynamic_register"
type      = "host"
# For register
node_id   = "70f52bd2-411a-bc3e-6244-2883e42568e9"
host_path = "/home/cloudmaster/shared_volumes/dynamic_register"
# mkdir is the default built-in plugin
plugin_id = "mkdir"


parameters = {
  mode = "0755"
  uid  = 1000
  gid  = 1000
}
