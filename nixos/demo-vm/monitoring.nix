{ config, pkgs, ... }:

let
  panel = id: title: unit: expr: x: y: {
    inherit id title;
    type = "timeseries";
    datasource = { type = "prometheus"; uid = "prometheus"; };
    gridPos = { inherit x y; w = 12; h = 8; };
    fieldConfig.defaults = { inherit unit; min = 0; };
    targets = [ { refId = "A"; inherit expr; } ];
  };

  dashboardDir = pkgs.writeTextDir "vm-overview.json" (builtins.toJSON {
    uid = "vm-overview";
    title = "NixOS VM — live metrics";
    schemaVersion = 39;
    version = 1;
    editable = false;
    refresh = "5s";
    time = { from = "now-15m"; to = "now"; };
    panels = [
      (panel 1 "CPU usage" "percent"
        ''100 * (1 - avg(rate(node_cpu_seconds_total{job="vm",mode="idle"}[1m])))'' 0 0)
      (panel 2 "Memory used" "percent"
        ''100 * (1 - node_memory_MemAvailable_bytes{job="vm"} / node_memory_MemTotal_bytes{job="vm"})'' 12 0)
      (panel 3 "Root disk used" "percent"
        ''100 * (1 - node_filesystem_avail_bytes{job="vm",mountpoint="/"} / node_filesystem_size_bytes{job="vm",mountpoint="/"})'' 0 8)
      (panel 4 "Network receive" "Bps"
        ''sum(rate(node_network_receive_bytes_total{job="vm",device!="lo"}[1m]))'' 12 8)
    ];
  });
in
{
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "1d";
    globalConfig.scrape_interval = "5s";
    scrapeConfigs = [
      {
        job_name = "vm";
        static_configs = [ { targets = [ "127.0.0.1:9100" ]; } ];
      }
    ];
    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        org_role = "Viewer";
      };
      security = {
        secret_key = "$__file{${config.services.grafana.dataDir}/secret-key}";
        admin_password = "$__file{${config.services.grafana.dataDir}/admin-password}";
      };
      dashboards.default_home_dashboard_path = "${dashboardDir}/vm-overview.json";
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          uid = "prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
          editable = false;
          jsonData.timeInterval = "1s";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "VM dashboards";
          type = "file";
          options.path = dashboardDir;
        }
      ];
    };
  };

  systemd.services.grafana.preStart = ''
    umask 077
    for name in secret-key admin-password; do
      path="${config.services.grafana.dataDir}/$name"
      if [[ ! -s "$path" ]]; then
        ${pkgs.openssl}/bin/openssl rand -hex 32 > "$path"
      fi
    done
  '';

  networking.firewall.allowedTCPPorts = [ 3000 ];
}
