#!/bin/bash

if [[ -f /usr/local/bin/wkhtmltopdf ]]
then
    echo "WKHTMLTOPDF already installed."
else
    echo "Installing WKHTMLTOPDF."
    wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb
    dpkg -i  wkhtmltox_0.12.6-1.buster_amd64.deb
    apt install -f
    wkhtmltopdf  -V
fi

if [[ -f /etc/clamav/clamd.conf ]]
then
    echo "Clamav is already installed."
else
    echo "Installing ClamAv."
    apt-get install clamav-daemon -y
    cd /etc/clamav/
    sed -i 's#MaxScanSize 100M#MaxScanSize 250M#g' clamd.conf
    sed -i 's#MaxFileSize 25M#MaxFileSize 250M#g' clamd.conf
    sed -i 's#MaxConnectionQueueLength 15#MaxConnectionQueueLength 50#g' clamd.conf
    sed -i 's#PCREMaxFileSize 25M#PCREMaxFileSize 250M#g' clamd.conf
    sed -i 's#StreamMaxLength 25M#StreamMaxLength 250M#g' clamd.conf
    /etc/init.d/clamav-daemon restart
fi

if [[ -f /etc/monit/conf.cloudways/clamav.conf ]]
then
    echo "Clamav is working via Monit."
else
    echo -e '[Service]\nExecStartPre=/bin/mkdir -p /run/clamav ; /bin/chown -R clamav /run/clamav' > /etc/systemd/system/clamav-daemon.service.d/chown.conf
    systemctl daemon-reload
    echo -e 'check process clamav with pidfile /var/run/clamav/clamd.ctl every 3 cycles\nstart program = "/etc/init.d/clamav-daemon start"\nstop program = "/etc/init.d/clamav-daemon stop"\nif failed unixsocket /var/run/clamav/clamd.ctl for 5 times within 5 cycles then restart\n\ncheck file clstate with path /etc/monit/services.cloudways/clamav\nif match "monitor=no" then exec "/usr/bin/monit unmonitor clamav"\nif match "monitor=yes" then exec "/usr/bin/monit monitor clamav"' > /etc/monit/conf.cloudways/clamav.conf
    cp /etc/monit/services.cloudways/apache2 /etc/monit/services.cloudways/clamav
    sed -i '/User clamav/a PidFile /var/run/clamav/clamd.ctl' /etc/clamav/clamd.conf
    /etc/init.d/monit restart
fi

echo "Installing Pre-requisite packages."

apt-get install swftools -y 
apt-get install xpdf -y
apt-get install libfreetype6 -y 
apt-get install libfreetype6-dev -y 
apt-get install libjpeg-dev -y 
apt-get install libjpeg8 -y
apt-get install zlib1g-dev -y

