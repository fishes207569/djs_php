FROM php:7.2-fpm
MAINTAINER cc "fishes207569@126.com"

ARG U_ID=1001

ARG G_ID=1001

ENV TZ=Asia/Chongqing

RUN ln -snf /usr/share/zoneinfo/Asia/Chongqing /etc/localtime && echo Asia/Chongqing > /etc/timezone

ENV LANG=C.UTF-8

RUN groupadd -g $G_ID www \
&& useradd -g www -d /var/www/html -u $U_ID www

RUN mkdir -p /data/logs/xdebug/profiler \
&& mkdir -p /data/logs/xdebug/trace \
&& mkdir -p /data/logs/crontab \
&& mkdir -p /var/log/supervisor \
&& touch /var/log/cron.log

# RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak \
# && > /etc/apt/sources.list \
# echo 'deb http://mirrors.ustc.edu.cn/debian stable main contrib non-free\n\
# deb-src http://mirrors.ustc.edu.cn/debian stable main contrib non-free\n\
# deb http://mirrors.ustc.edu.cn/debian stable-proposed-updates main contrib non-free\n\
# deb-src http://mirrors.ustc.edu.cn/debian stable-proposed-updates main contrib non-free\n'\
# >> /etc/apt/sources.list

RUN apt-get update -y && apt-get install -f -y \
    telnet locales ttf-wqy-zenhei apt-utils \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    openssl  \ 
    cron  \
    python2.7 libpython2.7-stdlib libncursesw5 libreadline7 libtinfo5 libfreetype6-dev libpng-dev \
    supervisor \ 
    rsyslog \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install gettext mysqli opcache pdo_mysql sockets fileinfo

RUN apt-get install -y \
    # for memcached
    libmemcached-dev \
    git \
    zip \
    vim \
    lrzsz

RUN pecl channel-update pecl.php.net \
    && pecl install xdebug \
    && pecl install redis \
    && pecl install swoole \
    && pecl install xlswriter-1.3.3.2

RUN docker-php-ext-enable xdebug redis swoole xlswriter

RUN docker-php-source delete \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
    && echo 'PHP 7.2 installed.'

COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY crontab/www /var/spool/cron/crontabs/www

RUN chown -R www:crontab /var/spool/cron/crontabs/www \
&& chmod 600 /var/spool/cron/crontabs/www

RUN sed -i -e 's@session    required     pam_loginuid.so@#session    required     pam_loginuid.so@g' /etc/pam.d/cron 

COPY rsyslog.conf /etc/rsyslog.conf

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"\
&& sed -i -e 's@;daemonize = yes@daemonize = no@g' /usr/local/etc/php-fpm.conf

ADD https://getcomposer.org/composer.phar /usr/local/bin/composer

RUN chmod 755 /usr/local/bin/composer

RUN echo "phar.readonly = Off" >> /usr/local/etc/php/php.ini

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/bin/supervisord","-c", "/etc/supervisor/supervisord.conf"]
