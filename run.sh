#!/bin/bash
#nohup /usr/bin/mongod &
#nohup nodejs bin/www &
#cd ../bindaas/bin
#sh startup.sh &

array=(${GCSFUSEMOUNTS//,/ })
for e in "${array[@]}"; 
do 
    mkdir -p /data/images/$e
    chown www-data:www-data /data/images/$e
    /bin/su -s /bin/bash -c "gcsfuse $e /data/images/$e" www-data; 
done

rm -f /var/run/apache2.pid
service apache2 start
htpasswd -bc /etc/apache2/.htpasswd admin quip2017
chmod 777 /etc/apache2/.htpasswd
/root/src/iipsrv/src/iipsrv.fcgi --bind 127.0.0.1:9001 &

apikey=$(python /var/www/html/createUser.py viewer@quip)

sed -i -e "s/APIKEY312/$apikey/g" /var/www/html/authenticate.php

while true; do sleep 1000; done
