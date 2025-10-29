#!/usr/bin/env bash
set -euo pipefail
docker build -t "cerise-sentinel:1.0" -f docker/Dockerfile .
