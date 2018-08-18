#!/bin/bash
#TeaSpeak updater by Nicer
#Tested on Debian

#checking for parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--force)
    FORCE="TRUE"
    shift # past argument
    ;;
    -p|--path)
    FOLDER="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--start)
    START="$2"
    shift # past argument
    shift # past value
    if [[ -z $START ]]
    then
      START="teastart.sh start"
    fi
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#main
if [ -z "$FOLDER" ]
then
        FOLDER="$(dirname "$(readlink -f "$0")")"
else
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
   echo "You are already using latest version of TeaSpeak. Nothing to update :)";
   exit 0;
fi

if [[ -z $FORCE ]];
then
	read -p "An update is available, do you want to update?" -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]];
	then
		echo "Aborting update"
		exit 0;
	fi
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

if [[ ! -z $START ]]
then
  echo "Starting server up";
  $FOLDER/$START;
fi
exit 0;
