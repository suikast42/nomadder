#!/bin/bash -e
grafana cli  --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-influxdb-flux-datasource &&
grafana cli  --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-clock-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-piechart-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install natel-discrete-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install natel-plotly-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install ae3e-plotly-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install neocat-cal-heatmap-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install savantly-heatmap-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install zuburqan-parity-report-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install briangann-datatable-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install vonage-status-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install blackmirror1-statusbygroup-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-polystat-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install flant-statusmap-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install fatcloud-windrose-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install mxswat-separator-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install novatec-sdg-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install magnesium-wordcloud-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install marcusolsson-gantt-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install volkovlabs-echarts-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install marcusolsson-treemap-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install netsage-slopegraph-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install cloudspout-button-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install esnet-matrix-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install integrationmatters-comparison-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install orchestracities-iconstat-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install auxmoney-waterfall-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-xyzchart-panel &&

#grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-synthetic-monitoring-app &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-oncall-app &&

grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install sbueringer-consul-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install volkovlabs-grapi-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install hamedkarbasi93-nodegraphapi-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install grafana-opcua-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install fzakaria-simple-annotations-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install innius-grpc-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install golioth-websocket-datasource &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install gapit-htmlgraphics-panel &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install mckn-funnel-panel &&

grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install  grafana-pyroscope-app &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install  grafana-lokiexplore-app  &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install  grafana-metricsdrilldown-app  &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install  grafana-exploretraces-app  &&
grafana cli --pluginsDir=$GF_PATHS_PLUGINS  plugins install  grafana-investigations-app  &&


echo All plugins are installed
