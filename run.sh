#!/bin/bash
#nohup /usr/bin/mongod &
#nohup nodejs bin/www &
#cd ../bindaas/bin
#sh startup.sh &

### gcsfuse-mount specified GCS buckets
array=(${GCSFUSEMOUNTS//,/ })
#for e in "${array[@]}"; 
#do 
#    mkdir -p /data/images/$e
#    chown www-data:www-data /data/images/$e
#    /bin/su -s /bin/bash -c "gcsfuse $e /data/images/$e" www-data; 
#done

### Configure apache2 to serve HTTPS
sed -i 's/ServerAdmin.*/ServerAdmin '$SERVER_ADMIN'/' /etc/apache2/sites-available/default-ssl.conf
sed -i '/ServerAdmin/a \ServerName '$SERVER_NAME'' /etc/apache2/sites-available/default-ssl.conf
sed -i '/ServerName/a \ServerAlias '$SERVER_ALIAS'' /etc/apache2/sites-available/default-ssl.conf
sed -i 's/SSLCertificateFile.*/SSLCertificateFile \/etc\/apache2\/ssl\/camic-viewer-apache.crt/' /etc/apache2/sites-available/default-ssl.conf
sed -i 's/SSLCertificateKeyFile.*/SSLCertificateKeyFile \/etc\/apache2\/ssl\/camic-viewer-apache.key/' /etc/apache2/sites-available/default-ssl.conf
a2enmod ssl
a2ensite default-ssl.conf

### Configure which website this VM goes to for slide metadata
sed -i 's|mvm-dot-isb-cgc.appspot.com|'$WEBAPP'|' /var/www/html/camicroscope/api/Configuration/config.php

rm -f /var/run/apache2.pid
service apache2 start
htpasswd -bc /etc/apache2/.htpasswd admin quip2017
chmod 777 /etc/apache2/.htpasswd
/root/src/iipsrv/src/iipsrv.fcgi --bind 127.0.0.1:9001 &

apikey=$(python /var/www/html/createUser.py viewer@quip)

sed -i -e "s/APIKEY312/$apikey/g" /var/www/html/authenticate.php

while true; do sleep 1000; done
