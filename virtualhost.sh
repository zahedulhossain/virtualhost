#!/bin/bash
usage="usage: virtualhost [option]

-c, --create      Create new virtualhost configurations
-d, --delete      Delete existing virtualhost configurations"

### Set default parameters
args=("-c" '--create' '-d' '--delete') 
action="$1"
domain="$2"
rootDir="$3"
owner=$(whoami)
email='webmaster'
sitesEnable='/etc/httpd/conf/sites-enabled/'
sitesAvailable='/etc/httpd/conf/sites-available/'
userDir='/srv/http/'


### don't modify from here unless you know what you are doing ####

if [ "$owner" != 'root' ]; then
  echo $"You don't have permission to run $0 as $owner, use sudo"
  exit 1;
fi

### check if the argument is valid
if [[ ! " ${args[@]} " =~ " $action " ]]; then
  echo -e "$usage"
  exit 1;
fi

### set domain name
while [ "$domain" == "" ]
do
  read -p "Provide a domain name, e.g. app.local, app.test $(echo $'\n> ')" domain
done

### set document root
if [ "$rootDir" == "" ]; then
  rootDir=${domain%.*}
fi

### if root dir starts with '/', don't use /srv/http as default starting point
if [[ "$rootDir" =~ ^/ ]]; then
  userDir=''
fi

rootDir=$userDir$rootDir
domainCFG=$sitesAvailable$domain.conf

if [ "$action" == '-c' ] || [ "$action" == '--create' ]; then
  ### check if domain config already exists
  if [ -e "$domainCFG" ]; then
    echo -e $"\nDomain config already exists in $sitesAvailable \n"
    echo -e $"Existing domains: \n$(ls $sitesAvailable) \n"
    echo -e $"Try again \n"
    exit;
  fi

  ### check if directory exists or not
  if ! [ -d "$rootDir" ]; then
    ### create the directory
    echo -e $"\nCreated $rootDir"
    mkdir "$rootDir"
    ### give permission to root dir
    chmod 755 "$rootDir"
    ### write test file in the new domain dir
    if ! echo "<?php echo phpinfo(); ?>" > "$rootDir"/info.php; then
      echo $"ERROR: Not able to write in file $rootDir/info.php. Please check permissions"
      exit;
    else
      echo -e $"\nAdded example content to $rootDir/info.php"
    fi
  fi

### create virtual host config file
configTemplate="
<VirtualHost *:80>
    ServerAdmin $email@$domain
    ServerName $domain
    ServerAlias $domain
    DocumentRoot $rootDir

    <Directory $rootDir>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>
    ErrorLog /var/log/httpd/$domain-error.log
    LogLevel error
    CustomLog /var/log/httpd/$domain-access.log combined
</VirtualHost>"

  if ! echo -e "$configTemplate" > "$domainCFG"; then
    echo -e $"ERROR creating $domain file"
    exit;
  else
    echo -e $"\nAdded config file in $sitesAvailable \n"
  fi

  ### Add domain in /etc/hosts
  if ! echo "127.0.0.1	$domain" >> /etc/hosts; then
    echo $"ERROR: Not able to write in /etc/hosts"
    exit;
  else
    echo -e $"Hostname added to /etc/hosts file \n"
  fi

  ### set ownership
  chown -R "$owner":"$owner" "$rootDir"

  ### enable website
  echo -e $"Site enabled\n"
  cp "$domainCFG" "$sitesEnable/$domain.conf"

  ### restart Apache
  echo -e $"Apache restarted \n"
  systemctl restart httpd

  ### show the finished message
  echo -e $"Complete! \nYou now have a new Virtual Host at: http://$domain \nAnd its located under $rootDir \n"
  exit;

else
  ### check whether domain config exists
  if ! [ -e "$domainCFG" ]; then
    echo -e $"\nDomain config does not exist in $sitesAvailable \n"
    echo -e $"Existing domains: \n$(ls $sitesAvailable) \n"
    echo -e $"Try again \n"
    exit;
  else
    ### Delete domain in /etc/hosts
    newhost=${domain//./\\.}
    sed -i "/$newhost/d" /etc/hosts

    ### disable website
    rm -f "$sitesEnable/$domain.conf"

    ### restart Apache
    systemctl restart httpd

    ### Delete virtual host config files
    rm "$domainCFG"
  fi

  ### check if directory exists or not
  if [ -d "$rootDir" ]; then
    echo -e $"Delete document root directory ? (y/n)"
    read -r deldir

    if [ "$deldir" == 'y' ] || [ "$deldir" == 'Y' ]; then
      ### Delete the directory
      rm -rf "$rootDir"
      echo -e $"\nDirectory deleted \n"
    else
      echo -e $"\nDirectory conserved \n"
    fi
  else
     echo -e $"\nDirectory not found. Ignored \n"
  fi

  ### show the finished message
  echo -e $"Complete!\nYou just removed Virtual Host $domain \n"
  exit 0;
fi
