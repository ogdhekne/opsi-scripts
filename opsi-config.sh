#!/bin/bash
# OPSI-CONFIGURATION SCRIPT

# variables
ip=$(ifconfig eth0 | awk 'NR==2 {print $2}' | sed 's/.....//')

# standard network configuration
network()
{
# host cofiguration
cat > /etc/hosts <<END
127.0.0.1	localhost.localdomain	locahost
$ip	opsi.vyom-labs.com	opsi
END

ping -c 1 opsi

# opsi configuration commands
opsi-setup --init-current-config
opsi-setup --set-rights
/etc/init.d/opsiconfd restart
/etc/init.d/opsipxeconfd restart
opsi-setup --auto-configure-samba

echo ""
echo "{ Login via  https://$ip:4447/configed/ | user/pass: admin1/123  }"
}

# dhcp network configuration
dhcp()
{
cat > /etc/network/interfaces <<END
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
END
}

# static network configuration
static()
{
# variables
adr=$(whiptail --inputbox "IP address:" 8 78  192.168.1.12 --title "Static IP" 3>&1 1>&2 2>&3)

netm=$(whiptail --inputbox "Netmask:" 8 78  255.255.255.0 --title "Static IP" 3>&1 1>&2 2>&3)

gate=$(whiptail --inputbox "Gateway:" 8 78  192.168.1.1 --title "Static IP" 3>&1 1>&2 2>&3)

# configure interfaces for static IP
cat > /etc/network/interfaces <<END
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
address $adr
netmask $netm
gateway $gate
END
}

# --------------------------------------------------------------------------- #

# main menu

while true; do
  FUN=$(whiptail --title "OPSI Network Config Options" --backtitle "Open PC Server Integration Configuration Script" --menu "Setup Options" 12 50 6 --cancel-button Finish --ok-button Select \
    "1" "Static IP" \
    "2" "DHCP" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    exit 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1) static ; network ;;
      2) dhcp ; network ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done
