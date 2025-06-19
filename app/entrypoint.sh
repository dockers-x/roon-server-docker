#!/bin/bash

echo "Starting RoonServer with user $(whoami)"

# Verify RoonServer installation (should already be installed during build)
if [ ! -f /opt/RoonServer/start.sh ]; then
  echo "Error: RoonServer not found! This should have been installed during Docker build."
  echo "Please check the Dockerfile and rebuild the image."
  exit 1
fi

echo "Verifying Roon installation"
if [ -f /opt/RoonServer/check.sh ]; then
  /opt/RoonServer/check.sh
  retval=$?
  if [ ${retval} != 0 ]; then
    echo "Verification of Roon installation failed."
    exit ${retval}
  fi
  echo "Roon installation verification passed"
else
  echo "Warning: check.sh not found, skipping verification"
fi

# start Roon
echo "Starting Roon Server..."
#
# since we're invoking from a script, we need to
# catch signals to terminate Roon nicely
/opt/RoonServer/start.sh &
roon_start_pid=$!

# Setup signal handlers
trap 'echo "Received signal, shutting down Roon Server..."; kill -INT ${roon_start_pid}' SIGINT SIGQUIT SIGTERM

# Wait for Roon to finish
wait "${roon_start_pid}"
retval=$?

echo "Roon Server stopped with exit code ${retval}"
exit ${retval}