#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

if [[ -n "${ALERTMANAGER_CONFIGURATION_FILE_OBJECT_PATH}" ]]; then
  echo "Fetching alertmanager configuration file."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${ALERTMANAGER_CONFIGURATION_FILE_OBJECT_PATH}" \
    /opt/alertmanager/conf/alertmanager.yml
else
  var_name="ALERTMANAGER_CONFIGURATION_FILE_OBJECT_PATH"
  echo "No ${var_name} provided. Using default configuration."
fi
