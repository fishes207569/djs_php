#!/bin/bash

set -x
chown www:crontab /var/spool/cron/crontabs/www
rm -rf /etc/default/locale
env >> /etc/default/locale

exec "$@"
