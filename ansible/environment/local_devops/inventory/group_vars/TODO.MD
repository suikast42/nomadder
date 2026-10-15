# Deployment  multi DC

# DC 1 consul servers
datacenter = "dc_nomad1"
retry_join = ["192.168.30.121"] # masters of dc_nomad1
        # Leave primary_datacenter blank or omit it (dc_nomad1 is the primary)
        # retry_join_wan is only needed if dc_nomad1 needs to initiate connection outward,
        # but typically secondary datacenters dial into the primary.
# DC 2 consul server 
datacenter = "dc_nomad2"
retry_join = ["192.168.30.122"] # masters of dc_nomad2
 
primary_datacenter = "dc_nomad1" #Designate dc_nomad1 as the authority/primary
retry_join_wan = ["192.168.30.121"] # Point WAN join ONLY to dc_nomad1's server IP
