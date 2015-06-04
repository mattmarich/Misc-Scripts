#!/bin/bash
#
# Author: Matt Marich
# Date: 6-4-15
#
# Restore script that looks to jailed directories for a specific client's most recent full and incremental backup, detects is full backup is newer than the incremental and combines if necessary. Then rsyncs over the prepared data directory to specified system
#

restoretime=`date +"%Y-%m-%d-%H-%M-%S"`
clear
echo "Please copy and paste the following portion on the remote host:";
echo ""
echo 'echo "<your_ssh_pubkey_here>" >> /root/.ssh/authorized_keys'
echo -e "\nPlease provide the IP address of the system we are restoring to: "
read IP
echo -e "\nDatabase backups to restore from:"
ls /home/jail/home
echo -e "\nEnter your selection (case sensitive): "
read SELECTION

rootdir=`echo /home/jail/home/$SELECTION`
restore=`ls -trp $rootdir | grep "full_" | grep "bz2" | tail -1`
restore_noext=`echo $restore | cut -d '.' -f 1`
fullrestore=`echo $rootdir'/'$restore`
incrrestore=`ls -trp $rootdir | grep "incremental_" | grep "bz2" | tail -1`
incrrestore_noext=`echo $incrrestore | cut -d '.' -f 1`
incrementalrestore=`echo $rootdir'/'$incrrestore`

echo -e "\nThis script detects if the most recent backup is a full or incremental. If full, only the full backup is transferred. if incremental then both the full and incremental are transferred then applied.\n"
	
	mkdir /tmp/restore_$restoretime
	cd /tmp/restore_$restoretime
	ssh root@$IP "rm -Rf /root/$SELECTION'_db_restore'"

if [[ $fullrestore -nt $incrementalrestore ]]; 
then
        echo "Copying the necessary files to /tmp/restore_$restoretime to prep"
	cp $fullrestore ./
        echo "Uncompressing Full Backup"
        bunzip2 $restore
	tar -xivf $restore_noext'.tar'
	rm -f ./*.tar
	echo -e "\e[1;32mPrepping the full backup\e[0m\n"
	innobackupex --apply-log ./
	rm -f /tmp/restore_$restoretime/xtrabackup*
	echo -e "\e[1;32mTransferring Restored Backup to $IP\e[0m\n"
	rsync -av --progress /tmp/restore_$restoretime/ root@$IP:/root/$SELECTION'_db_restore'/
        echo -e "\e[1;32mRemoving Temporary Files\e[0m\n"
        rm -Rf /tmp/restore_$restoretime
else
	echo "Copying the necessary files to /tmp/restore_$restoretime to prep"
	cp $fullrestore ./
	cp $incrementalrestore ./
	echo -e "\e[1;32mUncompressing Full Backup\e[0m\n"
	bunzip2 $restore
	tar -xivf $restore_noext'.tar'
	echo -e "\e[1;32mUncompressing Incremental Backup\e[0m\n"
	bunzip2 $incrrestore
	tar -xvf $incrrestore_noext'.tar' 
	rm -f ./*.tar
	echo -e "\e[1;32mPrepping the full backup\e[0m\n"
	innobackupex --apply-log --redo-only ./
	echo -e "\e[1;32mApplying the Incremental to Full Backup\e[0m\n"
	innobackupex --apply-log ./ --incremental-dir=$incrrestore_noext
	echo -e "\e[1;32mRolling back uncommitted transactions\e[0m\n"
	innobackupex --apply-log ./
	rm -Rf $incrrestore_noext
	rm -f /tmp/restore_$restoretime/xtrabackup*
	echo -e "\e[1;32mTransferring Restored Backup to $IP\e[0m\n"
	rsync -av --progress /tmp/restore_$restoretime/ root@$IP:/root/$SELECTION'_db_restore'/
	echo -e "\e[1;32mRemoving Temporary Files\e[0m\n"
	rm -Rf /tmp/restore_$restoretime
fi

echo -e "\e[1;31mDONT FORGET!!!\e[0m\n"
echo "move the mysql data directory in place and chown -R mysql. the directory"

exit 0
