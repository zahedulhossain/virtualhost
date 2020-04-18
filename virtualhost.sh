#!/bin/bash
usage="usage: virtualhost <option> [...]

-a,  all         Show available virtualhosts
-l,  list        List enabled virtualhosts
-e,  enable      Enable a virtualhost
-d,  disable     Disable a virtualhost
-c,  create      Create new virtualhost configuration
-rm, remove      Delete existing virtualhost configuration"

### Set default parameters
args=('-a' 'all' '-l' 'list' '-e' 'enable' '-d' 'disable' '-c' 'create' '-rm' 'remove')
action="$1"
domain="$2"
rootDir="$3"
owner=$(who am i | awk '{print $1}')
email="webmaster"
sitesEnable="/etc/httpd/conf/sites-enabled/"
sitesAvailable="/etc/httpd/conf/sites-available/"
userDir="/srv/http"


### don't modify from here unless you know what you are doing ####

if [[ $(whoami) != "root" ]]; then
  echo "Permission denied: run the command with sudo"
  exit 1
fi

if [[ ! -d $sitesAvailable ]]; then
  echo -e "Directory: $sitesAvailable doesn't exist in your system"
  exit 1
elif [[ ! -d $sitesEnable  ]]; then
  echo -e "Directory: $sitesEnable doesn't exist in your system"
  exit 1
fi

### check if the argument is valid
if [[ ! " ${args[@]} " =~ " $action " ]]; then
  echo -e "$usage"
  exit 1
fi

### declare functions
showAvailable() {
  echo -e "Available sites: \n---------------"
  ls -A1 "$sitesAvailable"
}

showEnable() {
  echo -e "Enabled sites: \n-------------"
  ls -A1 "$sitesEnable"
}

if [[ $action == '-a' || $action == 'all' ]]; then
  showAvailable
  exit 0
elif [[ $action == '-l' || $action == 'list' ]]; then
  showEnable
  exit 0
fi

### set domain name
while [[ $domain == "" ]]; do
  read -r -p "Provide a domain name, (e.g. app.local, app.test): " domain
done

### set document root
if [[ $rootDir == "" ]]; then
#  rootDir=${domain%.*}
#  rootDir=${domain//./}
  rootDir=${domain}
fi

### if root dir starts with '/', don't use /srv/http as default starting point
if [[ $rootDir =~ ^/ ]]; then
  userDir=""
fi

rootDir=$userDir$rootDir
domainCfgAvailable=$sitesAvailable$domain.conf
domainCfgEnable=$sitesEnable$domain.conf

enableSite() {
  if [[ -e $domainCfgEnable ]]; then
    echo "Site already enabled!"
    return 1
  fi

  if [[ -e $domainCfgAvailable ]]; then
    cp "$domainCfgAvailable" "$sitesEnable/$domain.conf"
    echo "Site enabled"
    ### restart Apache
    systemctl restart httpd
    echo "Apache restarted"
  else
    echo "Site doesn't exist!"
  fi
}


disableSite() {
  if [[ -e $domainCfgEnable ]]; then
    rm -f "$sitesEnable/$domain.conf"
    echo "Site disabled"
    ### restart Apache
    systemctl restart httpd
    echo "Apache restarted"
  else
    echo "Site isn't enabled!"
  fi
}


createSite() {
  ### check if domain config already exists
  if [[ -e "$domainCfgAvailable" ]]; then
    echo -e "Site already exists in $sitesAvailable"
    showAvailable
    echo -e "Try again! "
    exit 1
  fi

  ### check if it's for laravel application
  echo -n "Is it for Laravel application? (y/n): "
  while [[ $answer1 != [yn] ]]; do
    read -r -n 1 -s answer1
  done

  if [[ $answer1 == "y" ]]; then
    ### Delete the directory
    public="/public"
  else
    public=""
  fi

  ### check if directory already exists
  if [[ ! -d $rootDir ]]; then
    ### create the directory
    mkdir  -p "$rootDir$public"
    echo -e "\nCreated $rootDir"
    ### give permission to root dir
    chmod 755 "$rootDir"

    ### add test file in the new domain dir
    echo -n "Need example index file? (y/n): "
    while [[ $answer2 != [yn] ]]; do
      read -r -n 1 -s answer2
    done

    if [[ $answer2 == "y" ]]; then
      if ! echo "<?php echo phpinfo(); ?>" > "$rootDir$public"/index.php; then
        echo "ERROR: Not able to write in file $rootDir$public/index.php. Check permissions"
        exit 1
      else
        echo -e "\nAdded example content to $rootDir$public/index.php"
      fi
    fi

    ### update ownership
    if [[ $owner == "" ]]; then
			chown -R "$(whoami)":"$(whoami)" "$rootDir"
		else
      chown -R "$owner":"$owner" "$rootDir"
    fi
  fi

### create virtual host config file
configTemplate="
<VirtualHost *:80>
    ServerAdmin $email@$domain
    ServerName $domain
    ServerAlias $domain
    DocumentRoot $rootDir$public

    <Directory $rootDir$public>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride all
      Require all granted
    </Directory>
    ErrorLog /var/log/httpd/$domain-error.log
    LogLevel error
    CustomLog /var/log/httpd/$domain-access.log combined
</VirtualHost>"

  if ! echo -e "$configTemplate" > "$domainCfgAvailable"; then
    echo -e "ERROR creating $domain file"
    exit 1
  else
    echo -e "Site config created in $sitesAvailable"
  fi

  ### Add domain in /etc/hosts
  if ! echo "127.0.0.1	$domain" >> /etc/hosts; then
    echo "ERROR: Not able to write in /etc/hosts"
    exit 1
  else
    echo -e "Hostname added to /etc/hosts file"
  fi

  ### enable website
  enableSite

  ### show the finished message
  echo -e "Complete! \nYou now have a new Virtual Host at: http://$domain \nAnd its located under $rootDir"
}


removeSite() {
   ### check whether domain config exists
  if [[ ! -e $domainCfgAvailable ]]; then
    echo  "Site doesn't exist in $sitesAvailable"
    showAvailable
    echo  "Try again!"
    exit 1
  else
    ### Delete domain in /etc/hosts
    newhost=${domain//./\\.}
    sed -i "/$newhost/d" /etc/hosts

    ### disable website
    disableSite

    ### Delete virtual host config files
    rm "$domainCfgAvailable"
    echo "Site config removed"
  fi

  ### check if directory exists or not
  if [[ -d $rootDir ]]; then
    echo -n "Delete document root directory? (y/n): "
    while [[ $deldir != [yn] ]]; do
      read -r -n 1 -s deldir
    done

    if [[ $deldir == "y" ]]; then
      ### Delete the directory
      rm -rf "$rootDir"
      echo -e "\nDirectory deleted"
    else
      echo -e "\nDirectory conserved"
    fi
  else
     echo -e "\nDirectory not found. Ignored"
  fi

  ### show the finished message
  echo -e "Complete!\nYou just removed Virtual Host $domain"
}


if [[ "$action" == '-e' || "$action" == 'enable' ]]; then
  enableSite
  exit 0
elif [[ "$action" == '-d' ||  "$action" == 'disable' ]]; then
  disableSite
  exit 0
elif [[ "$action" == '-c' || "$action" == 'create' ]]; then
  createSite
  exit 0
else
  removeSite
  exit 0
fi
