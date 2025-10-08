#!/bin/bash

gdg tools contexts set grafana_local_restore

gdg backup dashboards clear
gdg backup alerting contactpoint clear
gdg backup alerting notifications clear
gdg backup alerting rules clear
gdg backup alerting templates clear
gdg backup dashboards clear
gdg backup libraryelements clear
gdg backup connections clear
gdg backup folders clear

gdg backup folders upload
gdg backup folders upload
gdg backup connections upload
gdg backup libraryelements upload
gdg backup alerting contactpoint upload
gdg backup alerting notifications upload
gdg backup alerting rules upload
gdg backup alerting templates upload
gdg backup dashboards upload



