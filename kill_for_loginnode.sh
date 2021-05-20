#!/bin/bash
#******************************************************************
# * Script   : kill_for_loginnode.sh
# * Author   : Cem Ahmet Mercan, 2019
# * Licence  : GNU General Public License v3.0
# *****************************************************************

# DIRECTORY FOR DETAILED LOG FILES PER KILL
MAINLOGDIR=/okyanus/SLURM/log/ps
# LOGFILE FOR ONE LINE INFO ABOUT KILLS
TOPLOGFILE=/okyanus/SLURM/log/loginnode-kills.txt

# PER USER LOAD LIMIT 500=load 5 (Kill user if user's load is more than this value)
# 28 core server's full load is 28, and for this variable 2800
LOADPERUSER=500
# PER USER LOAD CHECK LIMIT (Check users if node load is more than this value)
LOADLIMIT_PU=4
# TOTAL NODE LOAD LIMIT (Kill something if node load is more than this value)
# 28 core server's full load is 28
LOADLIMIT=20
# CPU TIME LIMIT
CPUTIMELIMIT=1500
# PER USER MEMORY CHECK LIMIT GB (Check users if free memory is less than this value)
FREEMEMLIMIT_PU=64
# MEMORY LIMIT GB (Kill something if free memory is less than this value)
FREEMEMLIMIT=20
# PER USER MEMORY LIMIT GB (Kill user if memory usage more than this value)
MEMPERUSER=20



NODELOAD=`uptime |awk '{sub(/\..*/,"",$(NF-2)); print $(NF-2)}'`


# NODE TOTAL LOAD LIMIT
if [ $NODELOAD -gt $LOADLIMIT ]
then
	KILLREASON=`top -b -n 1 -c -w 450 |head -n 8|tail -n 1 |awk '(($2 != "root") && ($2 != "nslcd") && ($2 != "polkitd") && ($2 != "munge") && ($2 != "slurm") && ($2 != "libstor+") && ($2 != "dbus") && ($2 != "postfix") && ($2 != "sshd") && ($2 != "easybuild") && ($2 != "easybuild32"))'`
	PROCESSID=`echo $KILLREASON |awk '{print $1}'`
	if [ "$PROCESSID" != "" ] 
	then
		echo "`date` LOAD: kill -9 $PROCESSID >> $KILLREASON" >>$TOPLOGFILE
		top -b -n 1 -c -w 450 >$MAINLOGDIR/LOAD-top-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		ps auxf >$MAINLOGDIR/LOAD-psauxf-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		OWNER=`ps -h -q $PROCESSID -o user:16`
		kill -9 $PROCESSID 2>&1 >/dev/null
		echo "
=========================================================
YOUR PROCESSES KILLED DUE TO EXCESSIVE NODE LOAD:
$KILLREASON
PLEASE DON'T RUN YOUR JOBS AT LOGINNODE  
=========================================================
		" |write $OWNER 2>/dev/null
		pkill -u $OWNER 2>&1 >/dev/null
	fi	
fi


# CPU TIME LIMIT
KILLREASON=`top -b -n 1 -c -o TIME -w 450 |head -n 8|tail -n 1 |awk '(($2 != "root") && ($2 != "nslcd") && ($2 != "polkitd") && ($2 != "munge") && ($2 != "slurm") && ($2 != "libstor+") && ($2 != "dbus") && ($2 != "postfix") && ($2 != "sshd") && ($2 != "easybuild") && ($2 != "easybuild32"))'`
DURATION2=`echo $KILLREASON |awk '{print $11}'`
DURATION="${DURATION2%%:*}"
PROCESSID=`echo $KILLREASON |awk '{print $1}'`
if [ "$DURATION" != "" ] && [ "${DURATION-0}" -gt $CPUTIMELIMIT ] && [ "$PROCESSID" != "" ]
then
	echo "`date` SURE: kill -9 $PROCESSID >> $KILLREASON" >>$TOPLOGFILE
	top -b -n 1 -c -o TIME -w 450 >$MAINLOGDIR/CPUTIME-topVIRT-`date '+%Y-%m-%d_%H-%M-%S'`.txt
	ps auxf >$MAINLOGDIR/CPUTIME-psauxf-`date '+%Y-%m-%d_%H-%M-%S'`.txt
	OWNER=`ps -h -q $PROCESSID -o user:16`
	kill -9 $PROCESSID 2>&1 >/dev/null
	echo "
=========================================================
YOUR PROCESSES KILLED DUE TO PROLONGED PROCESS TIME:
$KILLREASON
PLEASE DON'T RUN YOUR JOBS AT LOGINNODE  
=========================================================
		" |write $OWNER 2>/dev/null
		pkill -u $OWNER 2>&1 >/dev/null
fi




# NODE MEMORY LIMIT
FREEMEMORY=`free -g|awk '/^Mem:/{print $7}'`

if [ $FREEMEMORY -lt $FREEMEMLIMIT ]
then
	KILLREASON=`top -b -n 1 -c -o VIRT -w 450 |head -n 8|tail -n 1 |awk '(($2 != "root") && ($2 != "nslcd") && ($2 != "polkitd") && ($2 != "munge") && ($2 != "slurm") && ($2 != "libstor+") && ($2 != "dbus") && ($2 != "postfix") && ($2 != "sshd") && ($2 != "easybuild") && ($2 != "easybuild32"))'`
	PROCESSID=`echo $KILLREASON |awk '{print $1}'`
	if [ "$PROCESSID" != "" ] 
	then
		echo "`date` MEMO: kill -9 $PROCESSID >> $KILLREASON" >>$TOPLOGFILE
		top -b -n 1 -c -o VIRT -w 450 >$MAINLOGDIR/MEMO-topVIRT-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		ps auxf >$MAINLOGDIR/MEMO-psauxf-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		OWNER=`ps -h -q $PROCESSID -o user:16`
		kill -9 $PROCESSID 2>&1 >/dev/null
		echo "
============================================================
YOUR PROCESSES KILLED DUE TO EXCESSIVE MEMORY USAGE:
$KILLREASON
PLEASE DON'T RUN YOUR JOBS AT LOGINNODE  
============================================================
		" |write $OWNER 2>/dev/null
		pkill -u $OWNER 2>&1 >/dev/null
	fi
fi



# MEMORY LIMIT PER USER
if [ $FREEMEMORY -lt $FREEMEMLIMIT_PU ]
then
	KILLREASON=`ps ax ouser:16,%mem |awk '{liste[$1]+=$2} END {for (i in liste) printf "%5.1f %16s\n",liste[i],i}'|sort -nr|head -n 1|awk '(($2 != "root") && ($2 != "nslcd") && ($2 != "polkitd") && ($2 != "munge") && ($2 != "slurm") && ($2 != "libstor+") && ($2 != "dbus") && ($2 != "postfix") && ($2 != "sshd") && ($2 != "easybuild"))'`
	CPUPERCENT=`echo $KILLREASON |awk '{print $1}'`
	if [ "$CPUPERCENT" != "" ] && [ ${CPUPERCENT//.*} -gt $MEMPERUSER ] 
	then
		BADUSER=`echo $KILLREASON |awk '{print $2}'`
		echo "`date` UMEMO: pkill -u $BADUSER >> $KILLREASON" >>$TOPLOGFILE
		top -b -n 1 -c -w 450 >$MAINLOGDIR/UMEMO-top-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		ps auxf >$MAINLOGDIR/UMEMO-psauxf-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		echo "
============================================================
YOUR PROCESSES KILLED DUE TO EXCESSIVE MEMORY USAGE:
$KILLREASON
PLEASE DON'T RUN YOUR JOBS AT LOGINNODE  
============================================================
		" |write $BADUSER 2>/dev/null
		pkill -u $BADUSER 2>&1 >/dev/null
	fi	
fi




# LOAD LIMIT PER USER
if [ $NODELOAD -gt $LOADLIMIT_PU ]
then
	KILLREASON=`ps ax ouser:16,%cpu |awk '{liste[$1]+=$2} END {for (i in liste) printf "%5.1f %16s\n",liste[i],i}'|sort -nr|head -n 1|awk '(($2 != "root") && ($2 != "nslcd") && ($2 != "polkitd") && ($2 != "munge") && ($2 != "slurm") && ($2 != "libstor+") && ($2 != "dbus") && ($2 != "postfix") && ($2 != "sshd") && ($2 != "easybuild") && ($2 != "kdiri") && ($2 != "tdurak"))'`
	CPUPERCENT=`echo $KILLREASON |awk '{print $1}'`

	if [ "$CPUPERCENT" != "" ] && [ ${CPUPERCENT//.*} -gt $LOADPERUSER ] 
	then
		BADUSER=`echo $KILLREASON |awk '{print $2}'`
		#echo "$BADUSER kullanicisi yuzunden"
		echo "`date` ULOAD: pkill -u $BADUSER >> $KILLREASON" >>$TOPLOGFILE
		top -b -n 1 -c -w 450 >$MAINLOGDIR/ULOAD-top-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		ps auxf >$MAINLOGDIR/ULOAD-psauxf-`date '+%Y-%m-%d_%H-%M-%S'`.txt
		echo "
=========================================================
YOUR PROCESSES KILLED DUE TO EXCESSIVE NODE LOAD:
$KILLREASON
PLEASE DON'T RUN YOUR JOBS AT LOGINNODE  
=========================================================
		" |write $BADUSER 2>/dev/null
		pkill -u $BADUSER 2>&1 >/dev/null
	fi	
fi



