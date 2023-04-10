id        = "ebs_prod_db"
namespace = "default"
name      = "ebs_prod_db"
type      = "csi"
plugin_id = "hostpath-plugin"




# Optional: for 'nomad volume create', specify a maximum and minimum capacity.
# Registering an existing volume will record but ignore these fields.
capacity_min = "50MB"
capacity_max = "100MB"

# Required (at least one): for 'nomad volume create', specify one or more
# capabilities to validate. Registering an existing volume will record but
# ignore these fields.
capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}


# Optional: specify one or more locations where the volume must be accessible
# from. Refer to the plugin documentation for what segment values are supported.
#topology_request {
 # preferred {
 #   topology { segments { rack = "R1" } }
 # }
#  required {
#    topology { segments { rack = "R1" } }
#    topology { segments { rack = "R2", zone = "us-east-1a" } }
#  }
#}
