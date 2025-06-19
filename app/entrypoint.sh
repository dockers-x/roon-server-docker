#!/bin/bash

# Default to official Roon download if ROON_PACKAGE_URI is not set
ROON_PACKAGE_URI=${ROON_PACKAGE_URI:-"http://download.roonlabs.com/builds/RoonServer_linuxx64.tar.bz2"}

echo "Starting RoonServer with user $(whoami)"
echo "Using Roon package URI: ${ROON_PACKAGE_URI}"

# install Roon if not present
if [ ! -f /opt/RoonServer/start.sh ]; then
  echo "Downloading Roon Server from ${ROON_PACKAGE_URI}"
  
  # Download with better error handling
  if wget --progress=bar:force --tries=3 --timeout=30 -O - "${ROON_PACKAGE_URI}" | tar -xvj --overwrite -C /opt; then
    echo "Successfully downloaded and extracted Roon Server"
  else
    echo "Error: Unable to download or extract Roon Server from ${ROON_PACKAGE_URI}"
    echo "Please check if the URL is accessible and contains a valid RoonServer package"
    exit 1
  fi
else
  echo "Roon Server is already installed, skipping download"
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