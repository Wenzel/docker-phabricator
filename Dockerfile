#
# Docker image for running https://github.com/phacility/phabricator
#

FROM    debian:jessie
MAINTAINER  Yvonnick Esnault <yvonnick@esnau.lt>

ENV DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

# TODO: review this dependency list
RUN     apt-get update && apt-get install -y \
	        git \
            apache2 \
            curl \
            libapache2-mod-php5 \
            libmysqlclient18 \
            mercurial \
            mysql-client \
            php-apc \
            php5 \
            php5-apcu \
            php5-cli \
            php5-curl \
            php5-gd \
            php5-json \
            php5-ldap \
            php5-mysql \
            python-pygments \
            sendmail \
            subversion \
            python3 python3-virtualenv \
            tar \
            sudo \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

# For some reason phabricator doesn't have tagged releases. To support
# repeatable builds use the latest SHA
ADD     download.sh /opt/download.sh
WORKDIR /opt
RUN     bash download.sh phabricator 70c679110e1d4632d19ca160379f83f6f20d79d1
RUN     bash download.sh arcanist    ed476cf8489c4bf41b7a0075f15d40820d640fe4
RUN     bash download.sh libphutil   9c472e7c9b64395424c6cd25734bf239cb3c113d

# Setup apache
RUN     a2enmod rewrite
ADD     phabricator.conf /etc/apache2/sites-available/phabricator.conf
RUN     ln -s /etc/apache2/sites-available/phabricator.conf \
            /etc/apache2/sites-enabled/phabricator.conf && \
        rm -f /etc/apache2/sites-enabled/000-default.conf

# Setup phabricator
RUN     mkdir -p /opt/phabricator/conf/local /var/repo
ADD     local.json /opt/phabricator/conf/local/local.json
RUN     sed -e 's/post_max_size = 8M/post_max_size = 32M/' \
          -e 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' \
          -e 's/;opcache.validate_timestamps=1/opcache.validate_timestamps=0/' \
          -i /etc/php5/apache2/php.ini
RUN     ln -s /usr/lib/git-core/git-http-backend /opt/phabricator/support/bin
RUN     /opt/phabricator/bin/config set phd.user "root"
RUN     echo "www-data ALL=(ALL) SETENV: NOPASSWD: /opt/phabricator/support/bin/git-http-backend" >> /etc/sudoers

EXPOSE  80
ADD     entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD     ["start-server"]
