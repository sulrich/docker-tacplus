#!/bin/bash

TACPLUS=/tacacs/sbin/tac_plus
CONFIG_FILE=/etc/tac_plus/tac_plus.cfg

# check for config file 
if [ ! -f /etc/tac_plus/tac_plus.cfg ]; then
    echo "no configuration file at: ${CONFIG_FILE}"
    exit 1
fi

# check config file format
${TACPLUS} -P ${CONFIG_FILE}
if [ $? -ne 0 ]; then
    echo "configuration file errors"
    exit 1
fi

# generate tac_plus logging dir - this may be moved about by a container
# binding mount.
mkdir -p /var/log/tac_plus

echo "starting tac_plus..."
exec ${TACPLUS} -f ${CONFIG_FILE}
