#!/bin/bash

NGINX_ALL_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
SED=`which sed`
NGINX=`sudo which nginx`
CURRENT_DIR=`dirname $0`

if [ -z $1 ]; then
	echo "No domain name given"
	exit 1
fi
DOMAIN=$1

# check the domain is valid!
PATTERN="^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "Creating hosting for:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi

USERNAME='www-data'
HOME_DIR=$DOMAIN

# Now we need to copy the virtual host template
CONFIG=$NGINX_ALL_VHOSTS/$DOMAIN.conf
sudo cp $CURRENT_DIR/virtual_host.template $CONFIG
sudo $SED -i "s/DOMAIN/$DOMAIN/g" $CONFIG
sudo $SED -i "s#ROOT#$WEB_DIR/$HOME_DIR\/public_html#g" $CONFIG

#sudo usermod -aG $USERNAME nginx
#sudo chmod g+rxs $WEB_DIR/$USERNAME
sudo chmod 600 $CONFIG

sudo $NGINX -t
if [ $? -eq 0 ];then
	# Create symlink
	sudo ln -s $CONFIG $NGINX_ENABLED_VHOSTS/$DOMAIN.conf
else
	echo "Could not create new vhost as there appears to be a problem with the newly created nginx config file: $CONFIG";
	exit 1;
fi

sudo /etc/init.d/nginx reload

# put the template index.html file into the public_html dir!
sudo mkdir -p /var/www/$HOME_DIR/public_html

sudo cp $CURRENT_DIR/index.html.template $WEB_DIR/$HOME_DIR/public_html/index.html
sudo $SED -i "s/SITE/$DOMAIN/g" $WEB_DIR/$HOME_DIR/public_html/index.html
sudo chown $USERNAME:$USERNAME $WEB_DIR/$HOME_DIR/public_html -R

echo -e "\nSite Created for $DOMAIN"
echo "--------------------------"
echo "Host: "`hostname`
echo "URL: $DOMAIN"
echo "User: $USERNAME"
echo "--------------------------"
exit 0;