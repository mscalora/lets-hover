#!/usr/bin/env bash
cd /etc/letsencrypt-ssl
export HOVER_TOOL_CONFIG=$PWD/hover.config
bin/dehydrated -c

