#!/usr/bin/env bash

SOFTWARES="python curl"
MODULES="requests,requests builtins,future dns,dnspython tld,tld urllib3,urllib3 OpenSSL,pyopenssl"
FOLDERS="accounts bin certs .hover install"

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
MAG="$(tput setaf 5)"
NORM="$(tput sgr0)"

VEDITOR="${FCEDIT:-${VISUAL:-${EDITOR:-nano}}}"
if ! which "$ED" >/dev/null 2>&2 ; then
  VEDITOR=vi
fi

inquire ()  {
  echo  -n "$1 [y/n]? "
  read answer
  finish="-1"
  while [ "$finish" = '-1' ]
  do
    finish="1"
    if [ "$answer" = '' ];
    then
      answer=""
    else
      case "$answer" in
        y | Y | yes | YES ) answer="y";;
        n | N | no | NO ) answer="n";;
        *) finish="-1";
           echo -n 'Invalid response -- please reenter:';
           read answer;;
       esac
    fi
  done
}

{
  echo -e -n "\n${MAG}This setup makes use of the following open source software. "
  echo -n "To function correctly, the user account under which it runs, as a cron job,  must have read & write access to this directory and all of the subdirectories. "
  echo -n "Since certificates are sensitive data that should be kept secure, you should be comfortable with the software used. "
  echo -n "You are encouraged to visit the project pages and examine the source code for the software. "
  echo -n "The software is only updated when this script, ${GREEN}update-tools.sh${MAG}, is manually run. "
} | fold -sw 80
echo -e "\n${GREEN}"
echo -e "    dehydrated: https://github.com/lukas2511/dehydrated"
echo -e "    hover-cli:  https://github.com/mscalora/hover-cli"
echo -e "    lets-hover: https://github.com/mscalora/lets-hover"
echo -e "${NORM}"
inquire "${MAG}Do you wish to continue setup now?${NORM}"
if [[ "$answer" == "n" ]] ; then
  exit
fi

# check for required software
for SOFTWARE in $SOFTWARES ; do
  if ! which "$SOFTWARE" >/dev/null 2>&1 ; then
    echo -e "\n${MAG}Required software '${RED}$SOFTWARE${MAG}' not found, please install${NORM}\n"
    exit 1
  fi
done

# check for required python modules
for MODULE in $MODULES ; do
  [[ "$MODULE" =~ (.*),(.*) ]]
  IMPORT_NAME="${BASH_REMATCH[1]}"
  PIP_NAME="${BASH_REMATCH[2]}"
  if ! python -c "import ${IMPORT_NAME}" >/dev/null 2>&1 ; then
    echo -e "\n${MAG}Python '${RED}${PIP_NAME}${MAG}' module not installed, please install, usually like:${NORM}"
    echo -e "\n${GREEN}    pip install ${PIP_NAME}"
    if [[ "${PIP_NAME}" == "requests" ]] ; then
      echo -e "\n  ${MAG}For help installing ${RED}requests${MAG} see: http://docs.python-requests.org/en/master/user/install/${NORM}"
    fi
    echo ""
    exit 1
  fi
done

# check current directory
if [ "$PWD" != "/etc/letsencrypt-ssl" ] ; then
  echo -e "\n${RED}Scripts assume install directory is /etc/letsencrypt-ssl${NORM}"
  exit 1
fi

# check config template
CONFIG_NOT_DONE="$(fgrep -i xxx config | head -1)"
while [[ "$CONFIG_NOT_DONE" != "" ]] ; do
  echo -e "\n${RED}Configuration not complete:${NORM}"
  VAR="$(echo "$CONFIG_NOT_DONE" | egrep -o '^[^=]*')"
  echo -e "\n${GREEN}Please provide a value for ${MAG}$VAR${NORM} [just hit enter to cancel]"
  echo ""
  read -p "${MAG}$VAR=${NORM}" VALUE
  if [[ "$VALUE" == "" ]] ; then
    echo -e "\n${RED}Canceling setup${NORM}"
    exit 1
  fi
  ./file-replace.py -r config '^'"$VAR"'=.*' "$VAR=$VALUE"
  CONFIG_NOT_DONE="$(fgrep -i xxx config | head -1)"
done

# setup domains.txt
if [[ ! -f domains.txt ]] || fgrep example domains.txt /dev/null 2>&1 ; then
  echo -e  "\n${MAG}It appears that the ${RED}domains.txt${MAG} file contians the example content${NORM}"
  echo -e    "${GREEN} - It should have one or more lines of space separated domain names${NORM}"
  echo -e    "${GREEN} - Each line will create one certificate for all of the domaines on the line${NORM}"
  echo -e    "${GREEN} - DNS validation will be permormed on each and every domain, more domains takes longer${NORM}"
  echo -e    "${GREEN}${NORM}"
  echo -e -n "${MAG}Would you like to edit the domains.txt file now?${NORM}"
  inquire
  if [[ "$answer" == "y" ]] ; then
    "$VEDITOR" domains.txt
  fi
fi

# create folders as needed
echo ""
for d in $FOLDERS ; do
  if [[ ! -d "$d" ]]; then
    echo "${GREEN}Creating '$d' directory${NORM}"
    mkdir "$d"
  fi
done
echo ""

# download & install dehydrated script
echo -e "\n${GREEN}Downloading dehydrated BASH tool from github...${NORM}\n"
curl -L "https://codeload.github.com/lukas2511/dehydrated/zip/master" -o install/dehydrated.zip
echo -e "\n${GREEN}Installing dehydrated BASH tool...${NORM}\n"
unzip -jo install/dehydrated.zip "*/dehydrated" -d bin

# download & install hover-cli
echo -e "\n${GREEN}Downloading hover tool from github...${NORM}\n"
curl -L "https://github.com/mscalora/hover-cli/zipball/master/" -o install/hover-cli.zip
echo -e "\n${GREEN}Installing hover tool...${NORM}\n"
unzip -jo install/hover-cli.zip "*/hover*.py" -d bin

# hover credentials setup
if [ ! -f ".hover/hover-api-storage" ] ; then
  echo -e "\n${GREEN}Setup hover account credentials by entering accout info now...${NORM}\n"
fi

export HOVER_TOOL_CONFIG="$PWD/hover.config"
BACKUP=".hover/dns-backup-$(date "+%Y%m%dT%H%M%S").bash"
/etc/letsencrypt-ssl/bin/hover.py --backup --out "$BACKUP"
echo -e "\n${GREEN}Your current DNS entries have been backed up to $BACKUP${NORM}...\n\n"

echo -e "\n${GREEN}You can rerun this script at any time" '(as root, in the /etc/letsencrypt-ssl directory)' "to validate hover credentials and perform DNS backup${NORM}"

# cron job setup
if crontab -l | fgrep letsencrypt-cron >/dev/null 2>&1 ; then
  echo -e -n "\n${MAG}cron job appears to be installed already${NORM}"
else
  CRON1='21 2 * * 0 /etc/letsencrypt-ssl/letsencrypt-cron.sh >>/var/log/letsencrypt-ssl.cron.log 2>&1'
  CRON2='36 2 * * 0 /etc/letsencrypt-ssl/status-sender-cron.sh >>/var/log/letsencrypt-ssl.cron.log 2>&1'

  echo -e "\n${GREEN}Suggested cron settings:${NORM}\n"
  echo -e "    # check and reissues certs as needed weekly, Sunday mornig at 2:21am"
  echo    "    $CRON1"
  echo -e "    # send weekly certificate status, hover credential check and do DNS backup, Sunday at 2:36am [optional]"
  echo    "    $CRON2"
  echo -e ""
  echo -e -n "\n${MAG}Do you wish to automatically add these cron jobs?${NORM}"
  inquire
  if [[ "$answer" == "y" ]] ; then
    CTEMP="$(mktemp --tmpdir lets-cron.XXXXX)"
    crontab -l >"$CTEMP"
    echo "" >>"$CTEMP"
    echo "$CRON1" >>"$CTEMP"
    echo "$CRON2" >>"$CTEMP"
    crontab "$CTEMP"
    rm "$CTEMP"
  fi
fi

# set up letsencrypt account with dehydrated
echo -e "\n${GREEN}Testing ${MAG}dehydrated${GREEN} tool and setting up account${NORM}\n"
if ! bin/dehydrated --register ; then
  echo -e -n "\n${MAG}Do you wish to accept the terms of service?${NORM}"
  inquire
  if [[ "$answer" == "n" ]] ; then
    exit 1
  fi
  if ! bin/dehydrated --register --accept-terms ; then
    echo -e "\n${RED}Unexpected error running dehydrated --register, please correct and run again.${NORM}"
    exit 1
  fi
fi

# done
echo -e "\n${GREEN}Setup complete, you can now run the following command to issue certs:${NORM}"
echo -e "\n${GREEN}    ${MAG}./letsencrypt-cron.sh{GREEN} ${NORM}\n"
