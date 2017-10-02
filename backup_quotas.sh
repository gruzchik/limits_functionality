#!/bin/bash

# highlights color
Red='\e[0;31m'
Green='\e[0;32m'
Cyan='\e[0;36m'
Yellow='\e[0;33m'
NC='\e[0m'


function enterquota()
{
	# enter file quota
	flagEnterQuota=0
	while [[ $flagEnterQuota != 1 ]]; do
	        read -ep "Please enter a quota for user (in Gb):" NEWQUOTA
	        case ${NEWQUOTA} in
	                [0-9]* )
	                        echo -e "Quota for ${Green} ${NEWUSER} ${NC} is ${Green} ${NEWQUOTA} ${NC} Gb"
	                        flagEnterQuota=1
				let "UPDQUOTA = ${NEWQUOTA} * 1024 * 1024"
	                ;;
	                *)
	                        echo -e "Quota for user ${Yellow} $NEWUSER ${NC} is not correct, this value have to contain only digits. Please choose new one"
	                ;;
	        esac
	
	done
	
	# approve changes to the system
	#setquota -u -F vfsv0 ${NEWUSER} ${NEWQUOTA}000000 ${NEWQUOTA}000000 0 0 /home/
	setquota -u -F vfsv0 ${NEWUSER} ${UPDQUOTA} ${UPDQUOTA} 0 0 /home/

}


function createuser()
{
	# enter username
	flagEnterUser=0
	
	while [[ $flagEnterUser != 1 ]]; do
		IFEXISTS=0
		read -p "Please enter the name of backup user:" NEWUSER
		
		#IFEXISTS=$(cat /etc/passwd | awk 'BEGIN{FS=":"}{print $1}' |grep $NEWUSER| wc -l)
		
		# check user to exists in /etc/passwd
		for line in $(cat /etc/passwd | awk 'BEGIN{FS=":"}{print $1}' |grep $NEWUSER); do
			if [[ $line == $NEWUSER ]]; then
				IFEXISTS=1
			fi
		done
	
		if [[ $IFEXISTS == 1 ]]; then
			echo -e "User ${Yellow} $NEWUSER ${NC} is already exists in /etc/passwd. Please choose another name"
			continue
		fi
	
		echo -e "new user is ${Green} $NEWUSER ${NC}" 
		flagEnterUser=1
	
	done
	
	#enter home directory
	flagEnterHome=0
	
	while [[ $flagEnterHome != 1 ]]; do
		read -p "Please enter a home directory for user (/home/backup/*):" NEWHOMEFOLDER
	
			if [[ $NEWHOMEFOLDER == /home/backup/* ]]; then
				echo -e "home directory is user is ${Green} $NEWHOMEFOLDER ${NC}"
				flagEnterHome=1
			else
				echo -e "Folder ${Yellow} $NEWHOMEFOLDER ${NC} is not correct. Please choose new one"
			fi
	
	done
	
	# enter password
	read -p "Please enter a password for user:" NEWPASSWD
	
	# approve changes to the system
	#useradd -s /bin/bash -p $(openssl passwd -1 ${NEWPASSWD}) -d ${NEWHOMEFOLDER} ${NEWUSER}
	useradd -s /bin/bash -d ${NEWHOMEFOLDER} ${NEWUSER}
	echo ${NEWUSER}:${NEWPASSWD} | chpasswd
	mkdir -p ${NEWHOMEFOLDER}
	chown ${NEWUSER}:${NEWUSER} ${NEWHOMEFOLDER}
	
	enterquota
	
}

function updatequota()
{

	echo 'Please find a listing of users below:'
	repquota  -us /home
	
	flagUpdateUser=0
	while [[ $flagUpdateUser != 1 ]]; do
	        IFEXISTS=0
	        read -p "Please enter the name of user:" NEWUSER
	
	        #IFEXISTS=$(cat /etc/passwd | awk 'BEGIN{FS=":"}{print $1}' |grep $NEWUSER| wc -l)
	
	        # check user to exists in /etc/passwd
	        for line in $(cat /etc/passwd | awk 'BEGIN{FS=":"}{print $1}' |grep $NEWUSER); do
	                if [[ $line == $NEWUSER ]]; then
	                        IFEXISTS=1
	                fi
	        done
	
	        if [[ $IFEXISTS != 1 ]]; then
	                echo -e "User ${Yellow} $NEWUSER ${NC} is not exists in /etc/passwd. Please choose another name"
	                continue
	        fi
	
	        echo -e "update user is ${Green} $NEWUSER ${NC}"
	        flagUpdateUser=1
	
	done
	
	enterquota
}


function deleteuser()
{
	# delete user
	flagSelectUser=0
	repquota  -us /home
	while [[ $flagSelectUser != 1 ]]; do
	        read -p "Please select user to remove:" DELETEUSER
	
	        for line in $(cat /etc/passwd | awk 'BEGIN{FS=":"}{print $1}' |grep ${DELETEUSER}); do
	                if [[ $line == ${DELETEUSER} ]]; then
	                        IFEXISTS=1
	                fi
	        done
	
	        if [[ $IFEXISTS != 1 ]]; then
	                echo -e "User ${Yellow} ${DELETEUSER} ${NC} is not exists in /etc/passwd. Please choose another name"
	                continue
	        fi
	
		while true; do
			read -p "Do you want to remove user with home directory?:(Y/n)" options
			case "${options}" in
				Y | y | yes)
					userdel -r ${DELETEUSER}
					echo -e "User ${Yellow} ${DELETEUSER} ${NC} and home directory has been succesfully removed from system"; break
				;;
				N | n | no)
					userdel ${DELETEUSER}
					echo -e "User ${Yellow} ${DELETEUSER} ${NC} has been succesfully removed from system"; break
				;;
				*)
					echo "Option is not correct. Please answer 'yes' or 'no'"
			esac
		done

		exit
	
	done

}

# main functionality
echo ""
echo "Please select operations with backup users."
echo -en "${Cyan}"
cat << 'EOF'
Create user (C)
Delete user (D)
Update quota (U)
Show limits for users(repquota  -us /home) (S)

EOF
echo -en "${NC}"
#read -p "Please select operations with backup users. Create user(C) Delete user(D) Update quota(U) Show limits for users(S):" opts
read -p "Your choose is: " opts

        case "${opts}" in
                C | c)
                        echo 'Create user'
                        createuser
                        exit
                ;;
                D | d)
                        echo 'Delete user'
                        deleteuser
                        exit
                ;;
                U | u)
                        echo 'Update quota'
                        updatequota
                        exit
                ;;
                S | s)  
                        repquota  -us /home
                        exit
                ;;
                *)
                        echo "Option is not correct. Please make your choose"
                ;;

       esac
