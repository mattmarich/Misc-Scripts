#!/bin/bash
clear;
echo -e "Welcome to <hostname_her>, what can I assist you with?\n\n1. SSH To Another System\n2. Forwarding Rules\n\nEnter choice: ";
read WHATAMIHEREFOR
if [ "$WHATAMIHEREFOR" -eq "1" ] ; then
        clear;
        exit 0
fi
if [ "$WHATAMIHEREFOR" -eq "2" ] ; then
        /bin/bash /root/portforward.sh
fi
exit 0
