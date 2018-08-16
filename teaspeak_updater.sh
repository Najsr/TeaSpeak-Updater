#!/bin/bash
#TeaSpeak updater by Nicer
#Tested on Debian

#checking for parameters
for i in "$@"
do
	case $i in
   	-f|--force)
   	FORCE="true"
   	;;
   	-p=*|--path=*)
   	FOLDER="${i#*=}"
   	;;
   	*)
   	;;
	esac
done

#main
if [ -z "$FOLDER" ]
then
        FOLDER="$(dirname "$(readlink -f "$0")")"
else
        FOLDER="$1"
        if [[ $FOLDER == */ ]]
        then
                FOLDER=${FOLDER:0:(-1)}
        fi
fi

if [ ! -f "$FOLDER/buildVersion.txt" ] 
then
	echo "buildVersion.txt not found, cannot proceed with update!";
	exit 1;
fi

if [[ "$(uname -m)" == "x86_64" ]];
then
        arch="amd64"
else
        arch="x86"
fi

latest_version=$(curl -k --silent https://repo.teaspeak.de/server/linux/$arch/latest)
current_version=$(head -n 1 "$FOLDER/buildVersion.txt")
current_version=${current_version:11}

if [[ "$latest_version" == "$current_version" ]];
then
   echo "UPTODATE";
   exit 0;
fi

if [[ -z $FORCE ]];
then
        read -p "An update is available, do you want to update?" -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]];
        then
                echo "Aborting update"
                exit 0;
        fi
        echo
else
        echo "Found new version ($latest_version), starting update"
fi

echo "Checking for running server..."
if [[ $($FOLDER/teastart.sh status) == "Server is running" ]];
then
echo "Server is still running! Shutting it down..."
$FOLDER/teastart.sh stop
fi
echo "Downloading server version $latest_version";
wget -q -O /tmp/TeaSpeak.tar.gz https://repo.teaspeak.de/server/linux/$arch/TeaSpeak-$latest_version.tar.gz;
echo "Extracting it to $FOLDER/";
tar -C $FOLDER/ -xzf /tmp/TeaSpeak.tar.gz --overwrite
echo "Removing temporary file";
rm /tmp/TeaSpeak.tar.gz
echo "UPDATED";
exit 0;
