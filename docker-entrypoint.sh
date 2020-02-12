#!/bin/sh

cp -f -p -u -P -R /skosmos/view/* /var/www/html/skosmos/view/
cp -f -p -u -P -R /skosmos/plugins/* /var/www/html/skosmos/plugins/
cp -f -p -u -P -R /skosmos/resource/* /var/www/html/skosmos/resource/
cp -f -p -u -P -R /skosmos/favicon.ico /var/www/html/skosmos/
chown -R www-data:daemon /skosmos
chmod -R 770 /skosmos

set -e
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- apache2-foreground "$@"
fi
# Fix permissions : avoid different user:group in the exposed directory
chown -R www-data:daemon /var/www/html
# to allow webdav server to modify all files
chmod -R 770 /var/www/html
# to allow daemon to use temp directory
chmod 1777 /tmp

exec "$@"
