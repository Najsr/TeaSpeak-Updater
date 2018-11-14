#!/bin/bash
#TeaSpeak updater by Nicer
#Tested on Debian

#color codes from https://raw.githubusercontent.com/Sporesirius/TeaSpeak-Installer/master/teaspeak_install.sh
function warn() {
    echo -e "\\033[33;1m${@}\033[0m"
}

function error() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function info() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function green() {
    echo -e "\\033[32;1m${@}\033[0m"
}

function cyan() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function red() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellow() {
    echo -e "\\033[33;1m${@}\033[0m"
}


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
      START="teastart_autorestart.sh"
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
	error "buildVersion.txt not found, cannot proceed with update!";
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
   green "You are already using latest version of TeaSpeak. Nothing to update :)";
   exit 0;
fi

if [[ -z $FORCE ]];
then
	read -n 1 -r -s -p "$(yellow An update is available, do you want to update? [y/n])"
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]];
	then
		error "Aborting update"
		exit 0;
	fi
else
	info "Found new version ($latest_version), starting update"
fi

info "Checking for running server..."
if [[ $($FOLDER/teastart.sh status) == "Server is running" ]];
then
	info "Server is still running! Shutting it down..."
	$FOLDER/teastart.sh stop
fi
info "Backing up old server as TeaSpeakBackup_$current_version.tar.gz"
tar -C $FOLDER/ -zcvf TeaSpeakBackup_$current_version.tar.gz config.yml TeaData.sqlite --overwrite >/dev/null
info "Downloading server version $latest_version";
wget -q -O /tmp/TeaSpeak.tar.gz https://repo.teaspeak.de/server/linux/$arch/TeaSpeak-$latest_version.tar.gz;
info "Extracting it to $FOLDER/";
tar -C $FOLDER/ -xzf /tmp/TeaSpeak.tar.gz --overwrite
info "Removing temporary file";
rm /tmp/TeaSpeak.tar.gz
green "Update successfully completed!";

if [[ ! -z $START ]]
then
  info "Starting server up";
  $FOLDER/$START;
fi
exit 0;
