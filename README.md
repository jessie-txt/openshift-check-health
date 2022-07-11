# OpenShift informations gathering tool

A tool for gathering any information on your Openshift Cluster. Useful for Preventive Maintenance.

Author: Reinhart Utama

![menu](static/1.jpg)

## Features

* Check global Health Cluster (node readiness; cluster operator; MCP; cluster version; top usage of nodes) and create log information.
* Check resource utilization on every node (CPU, memory, disk usage, block device, uptime; default user: core).
* Check any expired certificate(s) on OpenShift-* namespace (only display).
* Check and list any expired certificate(s) on the OpenShift cluster and create log information.
* Prune unused /old/ build-cache images on every node.

Any gathered log information can be found on  _<current_dirrectory>_/pm_log/

## License

GPL v3.0

**A Simple Code can make Simple Life ^_^**
