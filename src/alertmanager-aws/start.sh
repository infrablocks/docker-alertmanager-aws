#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

echo "Running alertmanager."
exec /opt/alertmanager/bin/alertmanager
