#!/bin/bash
#
# Author: Matt Marich
# Date: 5-13-15
#
# Quick SSH Port Forwarding script that allows for ssh tunnels to be created for system users, need to make sure the users ssh pub keys are on the destination server or that they login via password
#

clear;

keeprunning=1;
while [ $keeprunning -eq 1 ]
do
	counter=0
	sshports=(2201 2202 2203 2204 2205 2206 2207 2208 2209 2210)

	### Reads current Tunneling rules	

	cat /dev/null > /root/.activeforwards
	ps aux | grep -v grep | grep -e "ssh.*-L.*-N" | awk '{ print $2,";"$15 }' | tr -d ' ' >> /root/.activeforwards

	### Primes the rule listing

	filecontent=( `cat "/root/.activeforwards" `)

	for i in "${filecontent[@]}"
	do
		counter=$[$counter+1]
		process[$counter]=`echo $i | cut -d ';' -f 1`;
		localport[$counter]=`echo $i | cut -d ';' -f 2 | cut -d ':' -f 2`;
		remotehost[$counter]=`echo $i | cut -d ';' -f 2 | cut -d ':' -f 3`;
		remoteport[$counter]=`echo $i | cut -d ';' -f 2 | cut -d ':' -f 4`;
		sshports=( "${sshports[@]/${localport[$counter]}}" );
	done

	availsshports=(${sshports[@]})

	echo -e "What do you want to do with the Fordwarding Rules?\n\n1. List\n2. Add\n3. Delete\n4. Exit\n\nEnter Choice:";
	read TASKTOCOMPLETE;

	##############################
	###       List Rules       ###
	##############################

	if [ "$TASKTOCOMPLETE" -eq "1" ] ; then
		clear;
		echo -e "ACTIVE FORWARDING RULES\n";
		loopcounter=0
		while [ $loopcounter -lt $counter ] ; do
			loopcounter=$[$loopcounter+1]
			echo "$loopcounter. By connecting to port: ${localport[$loopcounter]} this will redirect as ${remotehost[$loopcounter]}:${remoteport[$counter]}";
		done
	echo -e "\n";
	fi

	##############################
	###        Add Rule        ###
	##############################

	if [ "$TASKTOCOMPLETE" -eq "2" ] ; then
		clear;
		echo -e "ADD FORWARDING RULE\n";
		echo -e "1. SSH\n\nPlease select the rule type you would like to add: "
		read RULETYPE
		if [ "$RULETYPE" -eq "1" ] ; then
			echo "Enter server do you want to add the ssh forwarding rule for (FQDN or IP): "
			read REMOTESERVER;
			echo -e "Users:\n\n1. <user_1_here>\n2. <user_2_here>\n3. <user_3_here>\n4. <user_4_here>\n5. <user_5_here>"
			echo -e "\nSelect user (#): ";
			read USERSELECT;
			if [ "$USERSELECT" -eq "1" ] ; then
				selecteduser="<user_1_here>";
			fi
			if [ "$USERSELECT" -eq "2" ] ; then
				selecteduser="<user_2_here>";
			fi
			if [ "$USERSELECT" -eq "3" ] ; then
				selecteduser="<user_3_here>";
			fi
			if [ "$USERSELECT" -eq "4" ] ; then
				selecteduser="<user_4_here>";
			fi
			if [ "$USERSELECT" -eq "5" ] ; then
				selecteduser="<user_5_here>";
			fi

			### RUN RULE
			/usr/bin/ssh -f $selecteduser@$REMOTESERVER -L 0.0.0.0:${availsshports[0]}:$REMOTESERVER:22 -N		
		fi
	echo -e "\n";
	fi

	#############################
	### Modify or Remove Rule ###
	#############################

	if [ "$TASKTOCOMPLETE" -eq "3" ]; then
		clear;
		echo -e "REMOVE FORWARDING RULE\n";
		loopcounter=0
		while [ $loopcounter -lt $counter ] ; do
			loopcounter=$[$loopcounter+1]
			echo "$loopcounter. By connecting to port: ${localport[$loopcounter]} this will redirect to ${remotehost[$loopcounter]}:${remoteport[$counter]}";
		done

		echo -e "\nPlease select the rule you would like to Delete: "
		read RULEMOD
		echo "Are you sure you want to delete rule $RULEMOD which forwards local port: ${localport[$loopcounter]} to ${remotehost[$loopcounter]}:${remoteport[$counter]}? (y/n)";
		read CONFIRMREMOVAL
		if [ "$CONFIRMREMOVAL" == "n" ] || [ "$CONFIRMREMOVAL" == "N" ] ; then
			exit 0
		fi	
		if [ "$CONFIRMREMOVAL" == "y" ] || [ "$CONFIRMREMOVAL" == "Y" ] ; then
			kill -9 ${process[$RULEMOD]};
			echo -e "\nThe requested forwarding rule has been successfully removed";
		fi
	fi

	#############################
        ###         Exit          ###
        #############################

        if [ "$TASKTOCOMPLETE" -eq "4" ]; then
		keeprunning=0;
	fi
done

clear;
exit 0
