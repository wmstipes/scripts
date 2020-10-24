#!/bin/bash
#############################################################################
# Create a file to record changes

outputFile=./outputFiles/info.`date +%d-%m-%y:%H:%M:%S`
touch $outputFile

################################################################################
# Begin CIS remediation script
echo "" >> $outputFile
echo "################################################################################################" >> ./$outputFile
echo "Check user home directories and files therein" >> ./$outputFile
echo "" >> ./$outputFile

cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6}' | while read username directory
	do
			if [ ! -d "$directory" ]
				then
					echo "Warning! Home directory missing for user $username" >> ./$outputFile

			else
					echo "$username: $directory" >> ./$outputFile

dirperm=`ls -ld $directory | cut -f1 -d" "`
			if [ `echo $dirperm | cut -c6` != "-" ]
				then
					echo "Warning! Group write permissions incorrectly set on the home directory $directory" >> ./$outputFile
			else
					echo "Group wirte permissions correctly set on the home directory $directory" >> ./$outputFile
		fi

			if [ `echo $dirperm | cut -c8` != "-" ]
				then
					echo "Warning! Other read permissons incorrectly set on the home directory $directory" >> ./$outputFile
			else
					echo "Other read permissions correctly set on the home directory $directory" >> ./$outputFile
		fi

			if [ `echo $dirperm | cut -c9` != "-" ]
				then
					echo "Warning! Other write permissions incorrectly set on the home directory $directory" >> ./$outputFile
			else
					echo "Other write permissions correctly set on the home directory $directory" >> ./$outputFile
		fi

			if [ `echo $dirperm | cut -c10` != "-" ]
				then
					echo "Warning! Other execute permissions incorrectly set on the home directory $directory" >> ./$outputFile
			else
					echo "Other execute permission correctly set on the home directory $directory" >> ./$outputFile
		fi
		
owner=$(stat -L -c "%U" "$directory")
			if [ "$owner" != "$username" ]
				then
					echo "Warning! the home directory ($directory) of user $username is owned by $owner" >> ./$outputFile
			else
					echo "The home directory ($directory) of user $username is own by $username" >> ./$outputFile
		fi

for file in $directory/.[A-Za-z0-9]*
	do

			if [ ! -h "$file" -a -f "$file" ]
			then
				fileperm=`ls -ld $file | cut -f1 -d" "`
		fi

			if [ `echo $fileperm | cut -c6` != "-" ]
				then
					echo "Warning! Group write permissions incorrectly set on file $file" >> ./$outputFile
			else
					echo "Group write permisisons correctly set on file $file" >> ./$outputFile
		fi
	
			if [ `echo $fileperm | cut -c9` != "-" ];
				then
					echo "Warning! Other write permissions incorrectly s set on file $file" >> ./$outputFile
			else
					echo "Other write permissions correctly set on file $file" >> ./$outputFile
		fi
	
done

			if [ ! -h "$directory/.forward" -a -f "$directory/.forward" ]
				then
					echo "Warning! .forward file exists in directory $directory" >> ./$outputFile
			else
					echo "No .forward file found in directory $directory" >> ./$outputFile
		fi

			if [ ! -h "$directory/.netrc" -a -f "$directory/.netrc" ]
				then
					echo "Warning! .netrc file exists in directory $directory" >> ./$outputFile
			
for file in $directory/.netrc
	do

			if [ ! -h "$file" -a -f "$file" ]
				then
					fileperm=`ls -ld $file | cut -f1 -d" "`
		fi
			
			if [ `echo $fileperm | cut -c5` != "-" ]
				then
					echo "Warning! Group read permissions set on $file" >> ./$outputFile
		fi

			if [ `echo $fileperm | cut -c6` != "-" ]
				then
					echo "Warning! Group write permissions set on $file" >> ./$outputFile
		fi

			if [ `echo $fileperm | cut -c7` != "-" ]
				then
					echo "Warning! Group execute permissions set on $file" >> ./$outputFile
		fi

			if [ `echo $fileperm | cut -c8` != "-" ]
				then
					echo "Warning! Other read permissions set on $file" >> ./$outputFile
		fi

			if [ `echo $fileperm | cut -c9` != "-" ]
				then
					echo "Warning! Other write permissions set on $file" >> ./$outputFile
		fi

			if [ `echo $fileperm | cut -c10` != "-" ]
				then
					echo "Warning! Other execute permissions set on $file" >> ./$outputFile
		fi

done
				
			else
					echo "No .netrc file found in directory $directory" >> ./$outputFile
		fi
		
			if [ ! -h "$directory/.rhosts" -a -f "$directory/.rhosts" ]
				then
					echo "Warning! .rhosts file exists in directory $directory" >> ./$outputFile
			else
					echo "No .rhosts file found in directory $directory" >> ./$outputFile
		fi
			
					echo "" >> ./$outputFile
				
		fi
			
done

echo " " >> ./$outputFile
	
# Create a directory to store original copy of any files modified
mkdir -p backupFiles

echo " " >> ./$outputFile

# This script may modify /etc/sysctl.conf or any files in /etc/sysctl.d. 
# Simplest thing is to simply back up all these files in advance of running the script
mv /etc/sysctl.conf ./backupFiles/sysctl.conf.`date +%d-%m-%y:%H:%M:%S`
touch /etc/sysctl.conf
chmod 644 /etc/sysctl.conf

for file in $(ls /etc/sysctl.d/ | grep -v 99-sysctl.conf)
	do
		mv /etc/sysctl.d/$file ./backupFiles/$file.`date +%d-%m-%y:%H:%M:%S`
		touch /etc/sysctl.d/$file
		chmod 644 /etc/sysctl.d/$file
done

echo " " >> ./$outputFile

echo "################################################################################################" >> ./$outputFile
echo WARNING! >> ./$outputFile
echo "The original /etc/sysctl.conf file and any files in /etc/sysctl.d/ have been moved to ./backupFiles" >> ./$outputFile
echo "Please review these files and, if necessary, add lines from the originals to the new versions" >> ./$outputFile
echo " " >> ./$outputFile


# Install packages listed in yumInstall
echo "Install packages listed in yumInstall" >> ./$outputFile
file="/home/centos/inputFiles/yumInstall"

while IFS= read -r line
	do
		if ! [[ $(rpm -qa $line) ]];
			then
				yum -y install $line &>>/dev/null
				echo "$line has been installed on this system" >> ./$outputFile
	
			else
				echo "$line is already installed on this system" >> ./$outputFile
	fi
	
done <"$file"

echo " " >> ./$outputFile

# Remove packages listed in yumRemove
echo "Remove packages listed in yumRemove" >> ./$outputFile
file2="/home/centos/inputFiles/yumRemove"

while IFS= read -r line2
	do
		if [[ $(rpm -qa $line2) ]];
			then
				yum remove -y $line2 &>>/dev/null
				echo "$line2 has been removed from this system" >> ./$outputFile
	
			else
				echo "$line2 does not exist on this system" >> ./$outputFile
    fi
	
done <"$file2"

echo " " >> ./$outputFile

# CIS 1.1.21 - Ensure sticky bit is set on all world-writable directories (Scored)
echo "CIS 1.1.21 - Ensure sticky bit is set on all world-writable directories (Scored)" >> ./$outputFile

df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

echo "################################################################################################" >> ./$outputFile
echo "SETTING OF STICKY BIT ON WORLD WRITABLE FILES" >> ./$outputFile
echo "" >> ./$outputFile
echo "1.1.21 Sticky bit set on all world writable directories" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 1.1.1 Disable unused filesystems
echo "CIS 1.1.1 Disable unused filesystems" >> ./$outputFile
# Create the file /etc/modprobe.d/CIS.conf
if ls /etc/modprobe.d/CIS.conf
	then
		mv /etc/modprobe.d/CIS.conf ./backupFiles/CIS.conf`date +%d-%m-%y:%H:%M:%S`
		echo "################################################################################################" >> ./$outputFile
		echo WARNING! >> ./$outputFile
		echo CIS.conf already exists in /etc/modprobe.d/! >> ./$outputFile
		echo This file has been backed up>> ./$outputFile
		echo Please review this backup and, if necessary, add lines from the orignal to the new version >> ./$outputFile
fi
touch /etc/modprobe.d/CIS.conf

echo " " >> ./$outputFile

# Configure system to run fake install of filesystems in ././inputFiles/fileSystems on boot 
# Unload modules (should not be neccessary after a minimal install but better safe than sorry!)
# By default ././inputFiles/fileSystems includes all systems mentioned in CIS document
# It can be modified as appropriate 

echo "################################################################################################" >> ./$outputFile
echo "CIS 1.1.1 DISABLING OF UNNECESSARY FILESYSTEMS AND NETWORK PROTOCOLS" >> ./$outputFile
echo The following filesystems and network protocols have been disabled:  >> ./$outputFile

for file in /home/centos/inputFiles/fileSystems /home/centos/inputFiles/protocols
do
	while IFS= read -r module;
	do
		if lsmod | grep $module
		then
			rmmod $module
		fi
	
		if ! grep "install $module /bin/true" /etc/modprobe.d/CIS.conf
		then	
			echo install $module /bin/true >> /etc/modprobe.d/CIS.conf
		fi
	
	
	done < $file
done

echo " " >> ./$outputFile

# File system mount options:

# First create a backup of fstab
cp /etc/fstab ./backupFiles/fstab.`date +%d-%m-%y:%H:%M:%S`

# Set nodev, nosuid and noexec options on /tmp, /var/tmp and /dev/shm
sed -i "/\s\/tmp\s/ s/defaults\s/defaults,nosuid,nodev,noexec\t/" /etc/fstab
sed -i "/\s\/var\/tmp\s/ s/defaults\s/defaults,nosuid,nodev,noexec\t/" /etc/fstab

# Ensure settings for /dev/shm are correct (simpler just to delete relevant line and replace it!)
sed -i '/\/dev\/shm/d' /etc/fstab
	echo "tempfs	/dev/shm	tempsf	defaults,nosuid,nodev,noexec        0 0" >> /etc/fstab

echo " " >> ./$outputFile
	
# Remount /tmp and /var/tmp
mount -o remount /tmp
mount -o remount /var/tmp
mount -o remount /dev/shm

echo "################################################################################################" >> ./$outputFile
echo "FILESYSTEM MOUNT OPTONS:" >> ./$outputFile
echo "" >> ./$outputFile
echo nodev, nosuid and noexec options have been set for /tmp /var/tmp and /dev/shm >> ./$outputFile

echo " " >> ./$outputFile

# Removable media (see page 50 of CIS Benchmark Guide)
echo "Mount options for removable media have not been checked for this server." >> ./$outputFile
echo "If you have removable media see page 50 of CIS Benchmark Guide for instructions on setting mount options" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 1.3.1 - Ensure AIDE is installed (Scored)
echo "CIS 1.3.1 - Ensure AIDE is installed (Scored)" >> ./$outputFile

yum install aide -y
	echo "1.3.1 aide has been installed" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 1.3.2 - Ensure filesystem integrity is regularly checked (Scored)
echo "CIS 1.3.2 - Ensure filesystem integrity is regularly checked (Scored)" >> ./$outputFile

touch /etc/cron.allow
	echo "root" >> /etc/cron.allow
touch /var/spool/cron/root
/usr/bin/crontab /var/spool/cron/root
	echo "0 5 * * * /usr/sbin/aide --check" >> /var/spool/cron/root
	echo "1.3.2 aide has been set to check integrity every day at 5am as a cronjob for root within /var/spool/cron/root" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 1.8 - Ensure updates, patches, and additional security software are installed (Scored)
echo "CIS 1.8 - Ensure updates, patches, and additional security software are installed (Scored)" >> ./$outputFile

yum update -y --security
echo "1.8 security patches have been applied if applicable" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 1.4.1 - Ensure permissions on bootloader config are configured (Scored)
echo "CIS 1.4.1 - Ensure permissions on bootloader config are configured (Scored)" >> ./$outputFile

user=$(ls -al /boot/grub2/ | grep grub.cfg | awk '{print $3}')
group=$(ls -al /boot/grub2/ | grep grub.cfg | awk '{print $4}')
file=/boot/grub2/grub.cfg

if 	  [[ $user == "root" && $group != "root" ]]; then
        chown root:root $file
			echo "1.4.1 - \"grub.cfg\" group has been correctly set to \"root\" on this system - ownership was already set to \"root\"" >> ./$outputFile
elif  [[ $user != "root" && $group == "root" ]]; then
        chown root:root $file
			echo "1.4.1 - \"grub.cfg\" ownership has been correctly set to \"root\" on this system - group was already set to \"root\"" >> ./$outputFile
elif  [[ $user != "root" && $group != "root" ]]; then
        chown root:root $file
			echo "1.4.1 - \"grub.cfg\" ownership and group have been correctly set to \"root:root\" on this system" >> ./$outputFile
elif  [[ $user == "root" && $group == "root" ]]; then
			echo "1.4.1 - \"grub.cfg\" ownership and group have already been coreectly set to \"root:root\" on this system" >> ./$outputFile
fi

fperm=$(stat -c "%a %n" /boot/grub2/grub.cfg | awk '{print $1}')
file=/boot/grub2/grub.cfg
perm="600"

if [[ $fperm != "600" ]]; then
		chmod $perm $file
			echo "1.4.1 - \"grub.cfg\" permissions have been set to \"0600\" on this system" >> ./$outputFile
else
			echo "1.4.1 - \"grub.cfg\" permissions have already been set to \"0600\" on this system" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 2.1.1 - Ensure chargen services are not enabled (Scored)
# These services are part of the xinetd package, if installed this will remove it.
echo "CIS 2.1.1 - Ensure chargen services are not enabled (Scored)" >> ./$outputFile

service_exists() {
    n=xinetd
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}
if service_exists systemd-networkd; then
	yum remove -y $n &>>/dev/null
    echo "2.1.1 $n has been removed from this system" >> ./$outputFile
else
	echo "2.1.1 $n does not exist on this system" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 2.2.1.1 - Ensure time synchronization is in use (Not Scored)
echo "CIS 2.2.1.1 - Ensure time synchronization is in use (Not Scored)" >> ./$outputFile

if [ ! -f "/etc/ntp.conf" ]; then
   yum -y install ntp &>>/dev/null
    echo "2.2.1.1 - ntp has been installed on this system" >> ./$outputFile
else
  echo "2.2.1.1 - ntp is already exists on this system" >> ./$outputFile
fi

if [ ! -f "/etc/chrony.conf" ]; then
  yum -y install chrony &>>/dev/null
    echo "2.2.1.1 - chrony has been installed on this system" >> ./$outputFile
else
  echo "2.2.1.1 - chrony already exists on this system" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 2.2.1.2 - Ensure ntp is configured (Scored)
echo "CIS 2.2.1.2 - Ensure ntp is configured (Scored)" >> ./$outputFile

if [ -f "/etc/ntp.conf" ]; then
  grep -q "restrict -4 default kod nomodify notrap nopeer noquery" /etc/ntp.conf
  if [ `echo $?` == 1 ]; then
    echo "restrict -4 default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
	echo "2.2.1.2 restrict -4 default kod nomodify notrap nopeer noquery - has been set in /etc/ntp.conf" >> ./$outputFile
  fi
  grep -q "restrict -6 default kod nomodify notrap nopeer noquery" /etc/ntp.conf
  if [ `echo $?` == 1 ]; then
    echo "restrict -6 default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
	echo "2.2.1.2 restrict -6 default kod nomodify notrap nopeer noquery - has been set in /etc/ntp.conf" >> ./$outputFile
  fi
 fi
  if [ -f "/etc/sysconfig/ntpd" ]; then
    grep "^OPTIONS=\"-u ntp:ntp\"" /etc/sysconfig/ntpd
    if [ `echo $?` == 1 ]; then
      echo "OPTIONS=\"-u ntp:ntp\"" >> /etc/sysconfig/ntpd
	  echo "2.2.1.2 OPTIONS=\"-u ntp:ntp - has been set in /etc/sysconfig/ntpd" >> ./$outputFile
    fi
  fi
  if [ -f  "/usr/lib/systemd/system/ntpd.service" ]; then
    grep "^ExecStart=/usr/sbin/ntpd -u ntp:ntp $OPTIONS" /usr/lib/systemd/system/ntpd.service
    if [ `echo $?` == 1 ]; then
      sed -i "/\[Service\]/a ExecStart=/usr/sbin/ntpd -u ntp:ntp \$OPTIONS" /usr/lib/systemd/system/ntpd.service
      systemctl daemon-reload
    fi
  fi
  
# Configure time servers within ntp.conf and chrony.conf
oldtime1="server 0.centos.pool.ntp.org iburst"
oldtime2="server 1.centos.pool.ntp.org iburst"
oldtime3="server 2.centos.pool.ntp.org iburst"
oldtime4="server 3.centos.pool.ntp.org iburst"
newtime1="server time.server.1 iburst"
newtime2="server time.server.2 iburst"
newtime3="server time.server.3 iburst"
newtime4="server time.server.4 iburst"

sed -i "s/$oldtime1/$newtime1/g" /etc/ntp.conf
  echo "2.2.1.2 ntp has been configured on this system" >> ./$outputFile
  echo "$newtime1 has been set in /etc/ntp.conf" >> ./$outputFile
sed -i "s/$oldtime2/$newtime2/g" /etc/ntp.conf
  echo "$newtime2 has been set in /etc/ntp.conf" >> ./$outputFile
sed -i "s/$oldtime3/$newtime3/g" /etc/ntp.conf
  echo "$newtime3 has been set in /etc/ntp.conf" >> ./$outputFile
sed -i "s/$oldtime4/$newtime4/g" /etc/ntp.conf
  echo "$newtime4 has been set in /etc/ntp.conf" >> ./$outputFile

# Enable ntp
systemctl start ntpd
systemctl enable ntpd
echo "2.2.1.2 ntp has been started and enabled on this system" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 2.2.1.3 - Ensure chrony is configured (Scored)
echo "CIS 2.2.1.3 - Ensure chrony is configured (Scored)" >> ./$outputFile

  if [ -f "/etc/sysconfig/chronyd" ]; then
    grep "^OPTIONS=\"-u chrony\"" /etc/sysconfig/chronyd
    if [ `echo $?` == 1 ]; then
	  sed -i "s/OPTIONS=\"\"/OPTIONS=\"-u chrony\"/" /etc/sysconfig/chronyd
		echo "2.2.1.3 OPTIONS=\"-u chrony\" has been configured within /etc/sysconfig/chronyd on this system" >> ./$outputFile
    fi
  fi
  
# Configure time servers within chrony.conf 

sed -i "s/$oldtime1/$newtime1/g" /etc/chrony.conf
  echo "2.2.1.3 chrony.conf has been configured on this system" >> ./$outputFile
  echo "$newtime1 has been set in /etc/chrony.conf" >> ./$outputFile
sed -i "s/$oldtime2/$newtime2/g" /etc/chrony.conf
  echo "$newtime2 has been set in /etc/chrony.conf" >> ./$outputFile
sed -i "s/$oldtime3/$newtime3/g" /etc/chrony.conf
  echo "$newtime3 has been set in /etc/chrony.conf" >> ./$outputFile
sed -i "s/$oldtime4/$newtime4/g" /etc/chrony.conf
  echo "$newtime4 has been set in /etc/chrony.conf" >> ./$outputFile
  
# Enable chronyd if you are using chrony otherwise leave disabled and use ntp from above
# systemctl start chronyd
# systemctl enable chronyd
# echo "chrony has been started and enabled on this system" >> ./$outputFile
echo "2.2.1.3 chrony has not been started nor enabled on this system at this time" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 2.2.7 - Ensure NFS and RPC are not enabled (Scored)
echo "CIS 2.2.7 - Ensure NFS and RPC are not enabled (Scored)" >> ./$outputFile

if [ -f "/etc/systemd/system/multi-user.target.wants/nfs-server.service" ]; then
  systemctl disable nfs
	echo "2.2.7 nfs has been disabled on this system" >> ./$outputFile
  systemctl disable nfs-server
	echo "2.2.7 nfs-serve has been disabled on this system" >> ./$outputFile
else 
	echo "2.2.7 nfs-utils are not enabled on this system" >> ./$outputFile
fi

if [ -f "/etc/systemd/system/sockets.target.wants/rpcbind.socket" ]; then
  systemctl disable rpcbind
	echo "2.2.7 rpcbind has been disabled on this system" >> ./$outputFile
else
	echo "2.2.7 rpcbind is not enabled on this system" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 2.3.4 - Ensure telnet client is not installed (Scored)
echo "CIS 2.3.4 - Ensure telnet client is not installed (Scored)" >> ./$outputFile

if [[ $(rpm -qa telnet) ]];
			then
				yum remove -y telnet &>>/dev/null
				echo "CIS 2.3.4 telnet has been removed from this system" >> ./$outputFile
	
			else
				echo "telnet does not exist on this system" >> ./$outputFile
    fi

echo " " >> ./$outputFile
	
# CIS 3.3.1 - Ensure IPv6 router advertisements are not accepted (Scored)
echo "CIS 3.3.1 - Ensure IPv6 router advertisements are not accepted (Scored)" >> ./$outputFile

if [ -f "/proc/sys/net/ipv6/conf/all/accept_ra" ]; then
  sysctl -w net.ipv6.conf.all.accept_ra=0
    echo "3.3.1 - net.ipv6.conf.all.accept_ra=0 set in /proc/sys/net/ipv6/conf/all/accept_ra" >> ./$outputFile
  sysctl -w net.ipv6.conf.default.accept_ra=0
    echo "3.3.1 - net.ipv6.conf.default.accept_ra=0 set in /proc/sys/net/ipv6/conf/all/accept_ra" >> ./$outputFile
  sysctl -w net.ipv6.route.flush=1
    echo "net.ipv6.conf.all.accept_ra = 0" >> /etc/sysctl.conf
    echo "3.3.1 - net.ipv6.conf.all.accept_ra = 0 as been added to /etc/sysctl.conf" >> ./$outputFile
	echo "net.ipv6.conf.default.accept_ra=0" >> /etc/sysctl.conf
    echo "3.3.1 - net.ipv6.conf.default.accept_ra = 0 as been added to /etc/sysctl.conf" >> ./$outputFile
  
  else
    echo "net.ipv6.conf.all.accept_ra = 0" >> /etc/sysctl.conf
    echo "3.3.1 - net.ipv6.conf.all.accept_ra = 0 as been added to /etc/sysctl.conf" >> ./$outputFile
    echo "net.ipv6.conf.default.accept_ra=0" >> /etc/sysctl.conf
    echo "3.3.1 - net.ipv6.conf.default.accept_ra = 0 as been added to /etc/sysctl.conf" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 3.3.2 - Ensure IPv6 redirects are not accepted (Not Scored)
echo "CIS 3.3.2 - Ensure IPv6 redirects are not accepted (Not Scored)" >> ./$outputFile

if [ -f "/proc/sys/net/ipv6/conf/all/accept_redirects" ]; then
  sysctl -w net.ipv6.conf.all.accept_redirects=0
    echo "3.3.2 - \"net.ipv6.conf.all.accept_redirects=0\" set in /proc/sys/net/ipv6/conf/all/accept_redirects" >> ./$outputFile
  sysctl -w net.ipv6.conf.default.accept_redirects=0
    echo "3.3.2 - \"sysctl -w net.ipv6.conf.default.accept_redirects=0\" set in /proc/sys/net/ipv6/conf/all/accept_redirects" >> ./$outputFile
  sysctl -w net.ipv6.route.flush=1
    echo "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
    echo "3.3.2 - \"net.ipv6.conf.all.accept_redirects = 0\" as been added to /etc/sysctl.conf" >> ./$outputFile
	echo "net.ipv6.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
    echo "3.3.2 - \"net.ipv6.conf.default.accept_redirects = 0\" as been added to /etc/sysctl.conf" >> ./$outputFile
  
  else
    echo "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
    echo "3.3.2 - \"net.ipv6.conf.all.accept_redirects = 0\" as been added to /etc/sysctl.conf" >> ./$outputFile
	echo "net.ipv6.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
    echo "3.3.2 - \"net.ipv6.conf.default.accept_redirects = 0\" as been added to /etc/sysctl.conf" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 3.3.3 - Ensure IPv6 is disabled (Not Scored)
echo "CIS 3.3.3 - Ensure IPv6 is disabled (Not Scored)" >> ./$outputFile

grep ipv6.disable /etc/default/grub
if [ `echo $?` == 1 ]; then
  sed -i "s/GRUB_CMDLINE_LINUX=\"\(.*\)\"/GRUB_CMDLINE_LINUX=\"\1 ipv6.disable=1\"/" /etc/default/grub
	echo "3.3.3 - \"ipv6.disable=1\" has been added to /etc/default/grub" >> ./$outputFile
  grub2-mkconfig > /boot/grub2/grub.cfg
  else
	echo "3.3.3 - \"ipv6.disable=1\" exists in /etc/default/grub" >> ./$outputFile
  exit
fi

echo " " >> ./$outputFile


# CIS 3.4.1 - Ensure TCP Wrappers is installed (Scored)
echo "CIS 3.4.1 - Ensure TCP Wrappers is installed (Scored)" >> ./$outputFile

if ! [[ $(rpm -qa tcp_wrappers) ]];
			then
				yum install -y tcp_wrappers &>>/dev/null
				echo "3.4.1 - \"tcp_wrappers\" has been installed on this system" >> ./$outputFile
	
			else
				echo "3.4.1 - \"tcp_wrappers\" is already installed on this system" >> ./$outputFile
    fi

echo " " >> ./$outputFile

# CIS 3.6.5 - Ensure firewall rules exist for all open ports (Scored)
echo "CIS 3.6.5 - Ensure firewall rules exist for all open ports (Scored)" >> ./$outputFile
echo "NOTICE - Please review all ports created and remove any that are not needed" >> ./$outputFile

# tcp
for port in $(netstat -lnt |grep ^tcp | grep LISTEN | awk {'print $4'} | cut -d":" -f2); do
       iptables -A INPUT -p tcp --dport $port -m state --state NEW -j ACCEPT
	   echo "3.6.5 - An entry has been created in iptables INPUT for the following TCP Port: $port" >> ./$outputFile
done

# udp
for port in $(netstat -lnt |grep ^udp | grep LISTEN | awk {'print $4'} | cut -d":" -f2); do
       iptables -A INPUT -p udp --dport $port -m state --state NEW -j ACCEPT
	   echo "3.6.5 - An entry has been created in iptables INPUT for the following UDP Port: $port" >> ./$outputFile
done

echo " " >> ./$outputFile

# CIS 4.1.1.2 - Ensure system is disabled when audit logs are full (Scored)
echo "CIS 4.1.1.2 - Ensure system is disabled when audit logs are full (Scored)" >> ./$outputFile
echo "WARNING!!! This conrol can cause systems to halt, please ensure you have log rotation setup" >> ./$outputFile

# Backup file
cp /etc/audit/auditd.conf ./backupFiles/auditd.conf.`date +%d-%m-%y:%H:%M:%S`

egrep "^space_left_action = email" /etc/audit/auditd.conf
if [ `echo $?` == 1 ]; then
  sed -i "/^space_left_action =/ s/= .*/= EMAIL/" /etc/audit/auditd.conf
      echo "4.1.1.2 - \"space_left_action\" has been changed to \"EMAIL\" in /etc/audit/auditd.conf" >> ./$outputFile
else
      echo "4.1.1.2 - \"space_left_action\" is already set to \"EMAIL\" in /etc/audit/auditd.conf" >> ./$outputFile
fi

egrep "^action_mail_acct = root" /etc/audit/auditd.conf
if [ `echo $?` == 1 ]; then
  sed -i "/^action_mail_acct =/ s/= .*/= root/" /etc/audit/auditd.conf
      echo "4.1.1.2 - \"action_mail_acct\" has been changed to \"root\" in /etc/audit/auditd.conf" >> ./$outputFile
else
	  echo "4.1.1.2 - \"action_mail_acct\" is already set to \"root\" in /etc/audit/auditd.conf" >> ./$outputFile
fi

egrep "^admin_space_left_action = halt" /etc/audit/auditd.conf
if [ `echo $?` == 1 ]; then
  sed -i "/^admin_space_left_action =/ s/= .*/= HALT/" /etc/audit/auditd.conf
      echo "4.1.1.2 - \"admin_space_left_action\" has been changed to \"HALT\" in /etc/audit/auditd.conf" >> ./$outputFile
else
	  echo "4.1.1.2 - \"admin_space_left_action\" is already set to \"HALT\" in /etc/audit/auditd.conf" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.1.3 - Ensure audit logs are not automatically deleted (Scored)
echo "CIS 4.1.1.3 - Ensure audit logs are not automatically deleted (Scored)" >> ./$outputFile

egrep "max_log_file_action = keep_logs" /etc/audit/auditd.conf
if [ `echo $?` == 1 ]; then
  sed -i "/^max_log_file_action =/ s/= .*/= keep_logs/" /etc/audit/auditd.conf
      echo "4.1.1.2 - \"max_log_file_action\" has been changed to \"keep_logs\" in /etc/audit/auditd.conf" >> ./$outputFile
else
      echo "4.1.1.2 - \"max_log_file_action\" is already set to \"keep_logs\" in /etc/audit/auditd.conf" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.6 - Ensure events that modify the system's network environment are collected (Scored)
echo "CIS 4.1.6 - Ensure events that modify the system's network environment are collected (Scored)" >> ./$outputFile

# Backup file
cp /etc/audit/audit.rules ./backupFiles/audit.rules.`date +%d-%m-%y:%H:%M:%S`

grep "\-k system-locale" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
  if [[ $os_version = *"32-bit"* ]]; then
    echo "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/issue -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/issue -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/issue.net -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/issue.net -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/hosts -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/hosts -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/sysconfig/network -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/sysconfig/network -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/sysconfig/network-scripts/ -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/sysconfig/network-scripts/ -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  else
    echo "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/issue -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/issue -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/issue.net -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/issue.net -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/hosts -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/hosts -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/sysconfig/network -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/sysconfig/network -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/sysconfig/network-scripts/ -p wa -k system-locale" >> /etc/audit/audit.rules
		echo "4.1.6 - \"-w /etc/sysconfig/network-scripts/ -p wa -k system-locale\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  fi
fi

echo " " >> ./$outputFile

# CIS 4.1.7 - Ensure events that modify the system's Mandatory Access Controls are collected (Scored)
echo "CIS 4.1.7 - Ensure events that modify the system's Mandatory Access Controls are collected (Scored)" >> ./$outputFile

grep "\-k MAC-policy" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
    echo "-w /etc/selinux/ -p wa -k MAC-policy" >> /etc/audit/audit.rules
		echo "4.1.7 - \"-w /etc/selinux/ -p wa -k MAC-policy\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /usr/share/selinux/ -p wa -k MAC-policy" >> /etc/audit/audit.rules
		echo "4.1.7 - \"-w /usr/share/selinux/ -p wa -k MAC-policy\" has been added to /etc/audit/audit.rules" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.8 - Ensure login and logout events are collected (Scored)
echo "CIS 4.1.8 - Ensure login and logout events are collected (Scored)" >> ./$outputFile

grep "\-k logins" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
    echo "-w /var/log/lastlog -p wa -k logins" >> /etc/audit/audit.rules
		echo "4.1.8 - \"-w /var/log/lastlog -p wa -k logins\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /var/run/faillock/ -p wa -k logins" >> /etc/audit/audit.rules
		echo "4.1.8 - \"-w /var/run/faillock/ -p wa -k logins\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /var/log/wtmp -p wa -k logins" >> /etc/audit/audit.rules
		echo "4.1.8 - \"-w /var/log/wtmp -p wa -k logins\" has been added to /etc/audit/audit.rules" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.9 - Ensure session initiation information is collected (Scored)
echo "CIS 4.1.9 - Ensure session initiation information is collected (Scored)" >> ./$outputFile

grep "\-k session" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
    echo "-w /var/run/utmp -p wa -k session" >> /etc/audit/audit.rules
		echo "4.1.9 - \"-w /var/run/utmp -p wa -k session\" has been added to /etc/audit/audit.rules" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.10 - Ensure discretionary access control permission modification events are collected (Scored)
echo "CIS 4.1.10 - Ensure discretionary access control permission modification events are collected (Scored)" >> ./$outputFile

os_version=`file /usr/bin/file`
grep "\-k perm_mod" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
  if [[ $os_version = *"32-bit"* ]]; then
    echo "-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
	    echo "4.1.10 - \"-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
        echo "4.1.10 - \"-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  else
    echo "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
		echo "4.1.10 - \"-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  fi
fi

echo " " >> ./$outputFile

# CIS 4.1.11 - Ensure unsuccessful unauthorized file access attempts are collected (Scored)
echo "CIS 4.1.11 - Ensure unsuccessful unauthorized file access attempts are collected (Scored)" >> ./$outputFile

grep "\-k access" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
  if [[ $os_version = *"32-bit"* ]]; then
    echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
	    echo "4.1.11 - \"-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
		echo "4.1.11 - \"-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  else
    echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
		echo "4.1.11 - \"-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
		echo "4.1.11 - \"-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
		echo "4.1.11 - \"-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
		echo "4.1.11 - \"-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  fi
fi

echo " " >> ./$outputFile

# CIS 4.1.12 - Ensure use of privileged commands is collected (Scored)
echo "CIS 4.1.12 - Ensure use of privileged commands is collected (Scored" >> ./$outputFile

# Backup file
cp /etc/audit/rules.d/audit.rules ./backupFiles/rules.d-audit.rules.`date +%d-%m-%y:%H:%M:%S`

for dir in $(df -Ph | column -t | awk '{print $6}' | grep -v Mounted); do
       find $dir -xdev  \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged" }' >> /etc/audit/rules.d/audit.rules   
done

for command in $(grep path /etc/audit/rules.d/audit.rules | awk '{print $4}'); do
        echo "4.1.12 - An entry to capture the use of privileged commands has been created in /etc/audit/rules.d/audit.rules for \"$command\"" >> ./$outputFile
done

service auditd restart

echo " " >> ./$outputFile

# CIS 4.1.13 - Ensure successful file system mounts are collected (Scored)
echo "CIS 4.1.13 - Ensure successful file system mounts are collected (Scored)" >> ./$outputFile

grep "\-k mounts" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
  if [[ $os_version = *"32-bit"* ]]; then
    echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
	echo "4.1.13 - \"-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  else
    echo "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
	echo "4.1.13 - \"-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
	echo "4.1.13 - \"-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  fi
fi

echo " " >> ./$outputFile

# CIS 4.1.14 - Ensure file deletion events by users are collected (Scored)
echo "CIS 4.1.14 - Ensure file deletion events by users are collected (Scored)" >> ./$outputFile

grep "\-k deletes" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
  if [[ $os_version = *"32-bit"* ]]; then
    echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
		echo "4.1.14 - \"-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  else
    echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
		echo "4.1.14 - \"-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
		echo "4.1.14 - \"-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  fi
fi

echo " " >> ./$outputFile

# CIS 4.1.15 - Ensure changes to system administration scope (sudoers) is collected (Scored)
echo "CIS 4.1.15 - Ensure changes to system administration scope (sudoers) is collected (Scored)" >> ./$outputFile

grep "\-k scope" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
    echo "-w /etc/sudoers -p wa -k scope" >> /etc/audit/audit.rules
		echo "4.1.15 - \"-w /etc/sudoers -p wa -k scope\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /etc/sudoers.d/ -p wa -k scope" >> /etc/audit/audit.rules
		echo "4.1.15 - \"-w /etc/sudoers.d/ -p wa -k scope\" has been added to /etc/audit/audit.rules" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.16 - Ensure system administrator actions (sudolog) are collected (Scored)
echo "CIS 4.1.16 - Ensure system administrator actions (sudolog) are collected (Scored)" >> ./$outputFile

grep "\-k actions" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
    echo "-w /var/log/sudo.log -p wa -k actions" >> /etc/audit/audit.rules
		echo "4.1.16 - \"-w /var/log/sudo.log -p wa -k actions\" has been added to /etc/audit/audit.rules" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.1.17 - Ensure kernel module loading and unloading is collected (Scored)
echo "CIS 4.1.17 - Ensure kernel module loading and unloading is collected (Scored)" >> ./$outputFile

grep "\-k modules" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
  if [[ $os_version = *"32-bit"* ]]; then
    echo "-w /sbin/insmod -p x -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-w /sbin/insmod -p x -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /sbin/rmmod -p x -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-w /sbin/rmmod -p x -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /sbin/modprobe -p x -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-w /sbin/modprobe -p x -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b32 -S init_module -S delete_module -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-a always,exit -F arch=b32 -S init_module -S delete_module -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  else
    echo "-w /sbin/insmod -p x -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-w /sbin/insmod -p x -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /sbin/rmmod -p x -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-w /sbin/rmmod -p x -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-w /sbin/modprobe -p x -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-w /sbin/modprobe -p x -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
    echo "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" >> /etc/audit/audit.rules
		echo "4.1.17 - \"-a always,exit -F arch=b64 -S init_module -S delete_module -k modules\" has been added to /etc/audit/audit.rules" >> ./$outputFile
  fi
fi

echo " " >> ./$outputFile

# CIS 4.1.18 - Ensure the audit configuration is immutable (Scored)
echo "CIS 4.1.18 - Ensure the audit configuration is immutable (Scored)" >> ./$outputFile

grep "\-e 2" /etc/audit/audit.rules
if [ `echo $?` == 1 ]; then
    echo "-e 2" >> /etc/audit/audit.rules
		echo "4.1.18 - \"-e 2\" has been added to /etc/audit/audit.rules to make the audit configuration file immutable" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 4.2.3 Ensure rsyslog or syslog-ng is installed (Scored)
echo "CIS 4.2.3 Ensure rsyslog or syslog-ng is installed (Scored)" >> ./$outputFile

if ! [[ $(rpm -qa rsyslog) ]];
			then
				yum install -y rsyslog &>>/dev/null
				echo "4.2.3 - \"rsyslog\" has been installed on this system" >> ./$outputFile
	
			else
				echo "4.2.3 - \"rsyslog\" is already installed on this system" >> ./$outputFile
    fi

# CIS 4.2.1.1 - Ensure rsyslog Service is enabled (Scored)
echo "CIS 4.2.1.1 - Ensure rsyslog Service is enabled (Scored)" >> ./$outputFile

systemctl enable rsyslog
	echo "4.2.1.1 - \"rsyslog\" is enabled on this system" >> ./$outputFile

echo " " >> ./$outputFile

# CIS 4.2.1.2 - Ensure logging is configured (Not Scored)
# and
# CIS 4.2.1.3 - Ensure rsyslog default file permissions configured (Scored)
echo "CIS 4.2.1.2 - Ensure logging is configured (Not Scored)" >> ./$outputFile
echo "and" >> ./$outputFile
echo "CIS 4.2.1.3 - Ensure rsyslog default file permissions configured (Scored)" >> ./$outputFile

# Backup file
cp /etc/rsyslog.conf ./backupFiles/rsyslog.conf.`date +%d-%m-%y:%H:%M:%S`

# Clear /etc/rsyslog.conf
>/etc/rsyslog.conf

# Copy contents of outputFile "rsyslogConf" to "/etc/rsyslog.conf" 
yes | cp -f /home/centos/inputFiles/rsyslogConfig /etc/rsyslog.conf
	echo "4.2.1.2 - \"rsyslog.conf\" has been edited to reflect the configuration settings found in the CIS documentation" >> ./$outputFile
	echo "4.2.1.2 - These settings can be referenced from the file \"rsyslogConf\" found in the \"/inputFiles\" directory on this system" >> ./$outputFile
	echo "4.2.1.3 - \"FileCreateMode\" has been set to \"0640\" within \"/etc/rsyslog.conf\" on this system" >> ./$outputFile
	
# Set FileCreateMode to 0640 in any files found in /etc/rsyslog.d/ to ensure no lesser privileged files get created
for conf in /etc/rsyslog.d/*.*; do
    sed -i '1i\# Create all files with 0640 permissions' "$conf"
	sed -i '2i\$FileCreateMode 0640' "$conf"
	sed -i '3i\ ' "$conf"
	    echo "4.2.1.3 - \"FileCreateMode\" has been set to \"0640\" in \"$conf\" on this system" >> ./$outputFile
done

echo " " >> ./$outputFile

# CIS 5.2.1 - Ensure permissions on /etc/ssh/sshd_config are configured (Scored)
echo "CIS 5.2.1 - Ensure permissions on /etc/ssh/sshd_config are configured (Scored)" >> ./$outputFile

user=$(ls -al /etc/ssh/ | grep sshd_config | awk '{print $3}')
group=$(ls -al /etc/ssh/ | grep sshd_config | awk '{print $4}')
file=/etc/ssh/sshd_config

if 	  [[ $user == "root" && $group != "root" ]]; then
        chown root:root $file
			echo "5.2.1 - \"sshd_config\" group has been correctly set to \"root\" on this system - ownership was already set to \"root\"" >> ./$outputFile
elif  [[ $user != "root" && $group == "root" ]]; then
        chown root:root $file
			echo "5.2.1 - \"sshd_config\" ownership has been correctly set to \"root\" on this system - group was already set to \"root\"" >> ./$outputFile
elif  [[ $user != "root" && $group != "root" ]]; then
        chown root:root $file
			echo "5.2.1 - \"sshd_config\" ownership and group have been correctly set to \"root:root\" on this system" >> ./$outputFile
elif  [[ $user == "root" && $group == "root" ]]; then
			echo "5.2.1 - \"sshd_config\" ownership and group have already been coreectly set to \"root:root\" on this system" >> ./$outputFile
fi

fperm=$(stat -c "%a %n" /etc/ssh/sshd_config | awk '{print $1}')
file=/etc/ssh/sshd_config
perm="600"

if [[ $fperm != "600" ]]; then
		chmod $perm $file
			echo "5.2.1 - \"sshd_config\" permissions have been set to \"0600\" on this system" >> ./$outputFile
else
			echo "5.2.1 - \"sshd_config\" permissions have already been set to \"0600\" on this system" >> ./$outputFile
fi

echo " " >> ./$outputFile

# CIS 5.2.2 - Ensure SSH Protocol is set to 2 (Scored)
# CIS 5.2.3 - Ensure SSH LogLevel is set to INFO (Scored)
# CIS 5.2.4 - Ensure SSH X11 forwarding is disabled (Scored)
# CIS 5.2.5 - Ensure SSH MaxAuthTries is set to 4 or less (Scored)
# CIS 5.2.6 - Ensure SSH IgnoreRhosts is enabled (Scored)
# CIS 5.2.7 - Ensure SSH HostbasedAuthentication is disabled (Scored)
# CIS 5.2.8 - Ensure SSH root login is disabled (Scored)
# CIS 5.2.9 - Ensure SSH PermitEmptyPasswords is disabled (Scored)
# CIS 5.2.10 - Ensure SSH PermitUserEnvironment is disabled (Scored)
# CIS 5.2.11 - Ensure only approved MAC algorithms are used (Scored)
# CIS 5.2.12 - Ensure SSH Idle Timeout Interval is configured (Scored)
# CIS 5.2.13 - Ensure SSH LoginGraceTime is set to one minute or less (Scored)
# CIS 5.2.15 - Ensure SSH warning banner is configured (Scored)

echo "NOTICE - The following group of CIS Controls is handled as a group by \"inputFiles/sshd_config\"" >> ./$outputFile
echo " " >> ./$outputFile
echo "CIS 5.2.2 - Ensure SSH Protocol is set to 2 (Scored)" >> ./$outputFile
echo "CIS 5.2.3 - Ensure SSH LogLevel is set to INFO (Scored)" >> ./$outputFile
echo "CIS 5.2.4 - Ensure SSH X11 forwarding is disabled (Scored)" >> ./$outputFile
echo "CIS 5.2.5 - Ensure SSH MaxAuthTries is set to 4 or less (Scored)" >> ./$outputFile
echo "CIS 5.2.6 - Ensure SSH IgnoreRhosts is enabled (Scored)" >> ./$outputFile
echo "CIS 5.2.7 - Ensure SSH HostbasedAuthentication is disabled (Scored)" >> ./$outputFile
echo "CIS 5.2.8 - Ensure SSH root login is disabled (Scored)" >> ./$outputFile
echo "CIS 5.2.9 - Ensure SSH PermitEmptyPasswords is disabled (Scored)" >> ./$outputFile
echo "CIS 5.2.10 - Ensure SSH PermitUserEnvironment is disabled (Scored)" >> ./$outputFile
echo "CIS 5.2.11 - Ensure only approved MAC algorithms are used (Scored)" >> ./$outputFile
echo "CIS 5.2.12 - Ensure SSH Idle Timeout Interval is configured (Scored)" >> ./$outputFile
echo "CIS 5.2.13 - Ensure SSH LoginGraceTime is set to one minute or less (Scored)" >> ./$outputFile
echo "CIS 5.2.15 - Ensure SSH warning banner is configured (Scored)" >> ./$outputFile

# Backup file
cp /etc/ssh/sshd_config ./backupFiles/sshd_config.`date +%d-%m-%y:%H:%M:%S`

# Clear /etc/rsyslog.conf
>/etc/ssh/sshd_config

# Copy contents of outputFile "rsyslogConf" to "/etc/rsyslog.conf" 
yes | cp -f /home/centos/inputFiles/sshd_config /etc/ssh/sshd_config
	echo "5.2.Various - \"sshd_config\" has been edited to reflect the configuration settings found in the CIS documentation" >> ./$outputFile
	echo "5.2.Various - For more detailed information on what was modified within \"/etc/ssh/sshd_config\" please refer to the \"sshd_config\" file found in the \"inputFiles\" directory" >> ./$outputFile


echo " " >> ./$outputFile
echo "END " >> ./$outputFile