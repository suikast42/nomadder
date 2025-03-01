
// Nomad metric scrapping
prometheus.scrape "nomad_exporter" {
  job_name = "integrations/nomad"
  targets = [{
     __address__ = "localhost:4646", agent_hostname = "{{host_name}}",
  }]
  forward_to = [prometheus.relabel.job_to_hostname.receiver]
  params = {
    format = ["prometheus"],
  }
  scrape_interval = "10s"
  metrics_path = "/v1/metrics"
  scheme = "https"

  tls_config {
    ca_file = "{{cluster_intermediate_ca_bundle}}"
    cert_file = "{{nomad_cert}}"
    key_file = "{{nomad_cert_key}}"
  }
}



prometheus.exporter.unix "node_exporter" {

}

prometheus.scrape "scrape_node_exporter" {
  job_name = "integrations/node_exporter"
  targets = prometheus.exporter.unix.node_exporter.targets
  forward_to = [prometheus.relabel.relabel_node_exporter.receiver]
  scrape_interval = "15s"
}

prometheus.relabel "relabel_node_exporter" {
  forward_to = [prometheus.remote_write.metrics_integration_nomad.receiver]

  // Somehow the job_name of scrape_node_exporter not set. Lets do it again
  rule {
    target_label = "job"
    replacement = "integrations/node_exporter"
  }

  rule {
    target_label = "domainname"
    replacement = "{{tls_san}}"
  }

}

prometheus.exporter.consul "consul_exporter" {
  server = "https://localhost:8501"
  ca_file = "{{cluster_intermediate_ca_bundle}}"
  cert_file = "{{consul_cert}}"
  key_file = "{{consul_cert_key}}"
}

prometheus.scrape "scrape_consul_exporter" {
  job_name = "integrations/consul"
  targets = prometheus.exporter.consul.consul_exporter.targets
  forward_to = [prometheus.relabel.job_to_hostname.receiver]
  scrape_interval = "15s"
}


// Metric push endpoints
prometheus.remote_write "metrics_integration_nomad" {
  endpoint {
    name = "mimir"
    url = "http://mimir.service.consul:9009/api/v1/push"
  }
}

// Agent monitoriing
prometheus.scrape "selfmonitor" {
  job_name = "integrations/alloy"
  metrics_path = "/metrics"
  targets = [{__address__ = "127.0.0.1:12345",}]
  forward_to = [prometheus.relabel.job_to_hostname.receiver]
}

// Job to hosname
prometheus.relabel "job_to_hostname" {
  forward_to = [prometheus.remote_write.metrics_integration_nomad.receiver]
  rule {
    source_labels = ["instance"]
    target_label = "instance"
    replacement = "{{host_name}}"
  }
}
