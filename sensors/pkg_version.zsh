#!/bin/zsh

## Sensor to report if a pkg is installed according to its receipt, what version or timestamp

# You can create and set the variable for this sensor in WorkSpace ONE UEM, e.g.
# pkg_id=com.equinor.macos.equinor-anyconnect-settings
# pkg_id=com.air-watch.pkg.OSXAgent
# in that case, comment out the next line
# pkg_id="$1"


pkgutil=/usr/sbin/pkgutil

# regex match for the pkg_id at start of line
if $($pkgutil --pkgs | egrep --quiet "^$pkg_id" ); then
  # pkg_installed=true
  pkg_version=$($pkgutil --pkg-info $pkg_id |grep version | awk -F':' '{print $2}')
  # pkg_install_time_epoch=$($pkgutil --pkg-info $pkg_id |grep install-time | awk -F':' '{print $2}')
  # pkg_install_timestamp=$( date -r $pkg_install_time_epoch +%Y-%m-%d\ %H:%M:%S%z )
  echo "$pkg_version"
else
  # pkg_installed=false
  echo "NOT installed"
fi

exit 0



