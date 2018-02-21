#! /bin/bash
# This script is managed by Puppet
# is purpose is to measure files owned by root and add the security.ima
# attributed.
# It requires the ima-evm-util rpm to be installed.

which evmctl > /dev/null
if [ "$?" != "0" ]; then
  logger -p local6.warn "$0 - Failed because it could not find evmctl command.  Check if ima-evm-utils package installed and that the evmctl command is in the path."
else
  msg=$( find -P / -xautofs -uid 0 -executable \( -fstype xfs -o -fstype ext4 \) -type f ! -path /opt/puppetlabs/puppet/cache -exec evmctl ima_hash '{}' > /dev/null \;)
  logger -p local6.info "$0 completed.  $msg"
fi
