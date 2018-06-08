#!/bin/bash

# highlights color
Red='\e[0;31m'
Green='\e[0;32m'
Cyan='\e[0;36m'
Yellow='\e[0;33m'
NC='\e[0m'

EMAIL=""

while getopts u:p:c:q:a:m: opts; do
   case ${opts} in
	u) NEWUSER=${OPTARG} ;;
	p) NEWPASSWD=${OPTARG} ;;
        c) NAMECONTAINER=${OPTARG} ;;
        q) NEWQUOTA=${OPTARG} ;;
        a) ACTION=${OPTARG} ;;
	m) METHOD=${OPTARG} ;;
   esac
done

# Check for method option
if [[ "$METHOD" == "ftp" ]]; then
	if [[ -z ${NEWUSER} ]] || [[ -z ${ACTION} ]]; then
		echo "USER OR ACTION OPTION IS NOT SET when trying to use FTP METHOD"
		#echo "USER OR ACTION OPTION IS NOT SET when trying to use FTP METHOD" | mail -s "ftp account creation $(hostname -f) FAILURE" $EMAIL
		exit 1
	fi

	if [[ "${ACTION}" == "create" ]] && [[ -z ${NEWQUOTA} ]]; then
		echo "NEWQUOTA OPTION IS NOT SET when trying to use FTP METHOD"
                #echo "NEWQUOTA OPTION IS NOT SET when trying to use FTP METHOD" | mail -s "ftp account creation $(hostname -f) FAILURE" $EMAIL
		exit 1
	fi

	## create new FTP user
	# check user to exists in /etc/passwd
	IFEXISTS=0
        for line in $(cat /etc/passwd | awk 'BEGIN{FS=":"}{print $1}' |grep $NEWUSER); do
        	if [[ $line == $NEWUSER ]]; then
                	IFEXISTS=1
                fi
        done

        if [[ $IFEXISTS == 1 ]]; then
        	echo -e "User ${Yellow} $NEWUSER ${NC} is already exists in /etc/passwd. Please choose another name"
		#echo -e "User ${Yellow} $NEWUSER ${NC} is already exists in /etc/passwd. Please choose another name" | mail -s "ftp account creation $(hostname -f) FAILURE" $EMAIL
		exit 1
        fi
        echo -e "new user is ${Green} $NEWUSER ${NC}"

	# add home directory
	if [[ ${NAMECONTAINER} == mvs* ]]; then
        	NEWHOMEFOLDER="/home/backup/${NAMECONTAINER}/$NEWUSER"
                echo -e "home directory for user is ${Green} $NEWHOMEFOLDER ${NC}"
                #flagEnterHome=1
        elif [[ -z ${NAMECONTAINER} ]]; then
         	NEWHOMEFOLDER="/home/backup/$NEWUSER"
         	echo -e "home directory for user is ${Green} $NEWHOMEFOLDER ${NC}"
         	#flagEnterHome=1
        else
         	echo -e "Name of container ${Yellow} ${NAMECONTAINER} ${NC} is not correct. Please choose new one"
		echo -e "Name of container ${Yellow} ${NAMECONTAINER} ${NC} is not correct. Please choose new one" | mail -s "ftp account creation $(hostname -f) FAILURE" $EMAIL
		exit 1
        fi

	# enter password
        #read -p "Please enter a password for user:" NEWPASSWD
	if [[ -z ${NEWPASSWD} ]]; then
		echo -e "The value ${Yellow} NEWPASSWD ${NC} does not exists. Please choose it"
		#echo -e "The value ${Yellow} NEWPASSWD ${NC} does not exists. Please choose it" | mail -s "ftp account creation $(hostname -f) FAILURE" $EMAIL
		exit 1
	fi

        # approve changes to the system
        useradd -s /bin/bash -d ${NEWHOMEFOLDER} ${NEWUSER}
        echo ${NEWUSER}:${NEWPASSWD} | chpasswd
        mkdir -p ${NEWHOMEFOLDER}
        chown ${NEWUSER}:${NEWUSER} ${NEWHOMEFOLDER}

	# enter file quota
	echo -e "Quota for ${Green} ${NEWUSER} ${NC} is ${Green} ${NEWQUOTA} ${NC} Gb"
        #flagEnterQuota=1
        let "UPDQUOTA = ${NEWQUOTA} * 1024 * 1024"
	# approve changes to the system
        setquota -u -F vfsv0 ${NEWUSER} ${UPDQUOTA} ${UPDQUOTA} 0 0 /home/
	
fi
