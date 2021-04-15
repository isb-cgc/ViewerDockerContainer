# DOCKER-VERSION 0.3.4
# sshd, openjpeg2, openslide, iipsrv, apache
#
# VERSION               0.92

# this version provides
#	modified ruven iipsrv (ported changes from my fork of cytomine) with
#		misc bug fixes in resolution calculations.  since v0.3
#		fixed cache key hash. since v0.1.1
#		cache pointers (to avoid copy objects and object type casting).  since v0.2.1
#		openslide
#			calc best layer myself to avoid 4.000004 vs 4. since v0.1.1
#			fast ABGR to RGB.  since v0.1.1
#			fast area averaging for virtual tiles (instead of nearest neighbor). since v0.2
#			internal tile caching. since v0.2
#	modified openslide
#		using nearest neighbor except when generating virtual tiles (uses bilinear then). since v 0.3.1

FROM     ubuntu:18.04
MAINTAINER William Clifford "bcliffor@systemsbiology.org"

# build with
#  sudo docker build --rm=true -t="repo/imgname" .

### update
RUN apt-get -q update
RUN apt-get -q -y upgrade
RUN apt-get -q -y dist-upgrade
RUN apt-get clean
RUN apt-get -q update

# OpenSSH server
RUN apt-get -q -y install openssh-server

### need build tools for building openslide and later iipsrv
RUN apt-get -q -y install git autoconf automake make libtool pkg-config cmake

RUN mkdir /root/src

### install apache and dependencies. using fcgid
RUN apt-get -q -y install apache2 libapache2-mod-fcgid libfcgi0ldbl
RUN a2enmod rewrite
RUN a2enmod fcgid

### install php
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 apache2-utils libapache2-mod-php7.2 php7.2-mysql php7.2-gd php-pear php-apcu php7.2-curl curl lynx-common lynx


# Enable apache mods.
RUN a2enmod php7.2
RUN a2enmod rewrite


# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.2/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.2/apache2/php.ini
RUN sed -i "s/; max_input_vars = 1000/max_input_vars = 100000/" /etc/php/7.2/apache2/php.ini


## get our configuration files
WORKDIR /root/src
RUN git clone https://tcpan@bitbucket.org/tcpan/iip-openslide-docker.git

## replace apache's default fcgi config with ours.
RUN rm /etc/apache2/mods-enabled/fcgid.conf
RUN ln -s /root/src/iip-openslide-docker/apache2-iipsrv-fcgid.conf /etc/apache2/mods-enabled/fcgid.conf

## enable proxy
RUN ln -s /etc/apache2/mods-available/proxy_http.load /etc/apache2/mods-enabled/proxy_http.load
RUN ln -s /etc/apache2/mods-available/proxy.load /etc/apache2/mods-enabled/proxy.load
RUN ln -s /etc/apache2/mods-available/proxy.conf /etc/apache2/mods-enabled/proxy.conf
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

## Add configuration file
COPY apache2.conf /etc/apache2/apache2.conf

## expose some ports
#EXPOSE 80
#EXPOSE 443

## setup a mount point for images.  - this is external to the docker container.
RUN mkdir -p /mnt/images

### set up the ssh daemon
RUN mkdir /var/run/sshd
RUN echo 'root:iipdocker' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
## expose some ports
EXPOSE 22



### prereqs for openslide
# For 64-bit - Linux (Ubuntu Trusty) - Ubuntu 18.0.4
RUN wget http://se.archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb
RUN dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb

#RUN apt-get -q -y install zlib1g-dev libpng12-dev libjpeg-dev libtiff5-dev libgdk-pixbuf2.0-dev libxml2-dev libsqlite3-dev libcairo2-dev libglib2.0-dev
RUN apt-get -q -y install zlib1g-dev libjpeg-dev libtiff5-dev libgdk-pixbuf2.0-dev libxml2-dev libsqlite3-dev libcairo2-dev libglib2.0-dev

WORKDIR /root/src

### openjpeg version in ubuntu 14.04 is 1.3, too old and does not have openslide required chroma subsampled images support.  download 2.1.0 from source and build
RUN wget http://sourceforge.net/projects/openjpeg.mirror/files/2.1.0/openjpeg-2.1.0.tar.gz
RUN tar xvfz openjpeg-2.1.0.tar.gz
RUN mkdir /root/src/openjpeg-bin
WORKDIR /root/src/openjpeg-bin
RUN cmake -DBUILD_JPIP=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DBUILD_CODEC=ON -DBUILD_PKGCONFIG_FILES=ON /root/src/openjpeg-2.1.0
RUN make
RUN make install

### Openslide
WORKDIR /root/src
## get my fork from openslide source cdoe
RUN git clone https://bitbucket.org/tcpan/openslide.git

## build openslide
WORKDIR /root/src/openslide
RUN git checkout tags/v0.3.1
RUN autoreconf -i
#RUN ./configure --enable-static --enable-shared=no
# may need to set OPENJPEG_CFLAGS='-I/usr/local/include' and OPENJPEG_LIBS='-L/usr/local/lib -lopenjp2'
# and the corresponding TIFF flags and libs to where bigtiff lib is installed.
RUN ./configure
RUN make
RUN make install

###  iipsrv
WORKDIR /root/src
RUN apt-get -q -y install g++ libmemcached-dev libjpeg-turbo8-dev
## fork from Ruven's iipsrv repo
RUN git clone https://bitbucket.org/tcpan/iipsrv.git iipsrv

## build iipsrv
WORKDIR /root/src/iipsrv
RUN git checkout tags/iip-openslide-v0.3.1
RUN ./autogen.sh
#RUN ./configure --enable-static --enable-shared=no
RUN ./configure
RUN make

## creare a directory in which the goofys fuse file system will find interoperability credentials
RUN mkdir /var/www/.aws

## create a directory for iipsrv's fcgi binary
RUN mkdir -p /var/www/localhost/fcgi-bin/
RUN cp /root/src/iipsrv/src/iipsrv.fcgi /var/www/localhost/fcgi-bin/

# Security and authentication
RUN apt-get update && apt-get -y upgrade
RUN apt-get -q -y install php7.2-dev
#RUN pecl install mongo
#RUN sed -i "2i extension=mongo.so" /etc/php/7.2/apache2/php.ini



### run the script to start apache and sshd and keep the container running.
# use "service apache2 start"
#CMD ["/usr/sbin/sshd", "-D"]
#COPY html /var/www/html/
#RUN rm -rf /var/www/html
#RUN git clone -b release  https://github.com/camicroscope/Security.git /var/www/html
#RUN git clone -b release https://github.com/camicroscope/caMicroscope.git /var/www/html/camicroscope

#RUN service apache2 start

### moving this closer to the end of the build so we can change and quickly rebuild
#COPY apache2-iipsrv-fcgid.conf /root/src/iip-openslide-docker/apache2-iipsrv-fcgid.conf

RUN pear install http_request2
#COPY run.sh /root/run.sh
### Seem to need to do an update in order to successfully install default-jdk
RUN apt-get update && apt-get -y upgrade
RUN  apt-get install -y default-jdk

COPY html/FlexTables/ /var/www/html/FlexTables/
COPY html/featurescapeapps/ /var/www/html/featurescapeapps/

#### Shouldn't need gcsfuse. Using goofys
#### Install gcsfuse
#RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-`lsb_release -c -s` main" | tee /etc/apt/sources.list.d/gcsfuse.list
#RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#RUN apt-get -y update
#RUN apt-get -y install gcsfuse

COPY run.sh /root/run.sh

RUN rm -rf /var/www/html
### This version disables security checking
### The original camicroscope_release branch of the Security repo seems to have been deleted. So create
### equivalent branch from specified commit
RUN git clone https://github.com/camicroscope/Security.git /var/www/html
WORKDIR /var/www/html 
RUN git branch camicroscope_release 52c7c2959b220725734e252607b8fd3866bd4efd
RUN git checkout camicroscope_release
WORKDIR /root/src
### Clone the isb-cgc version
RUN git clone -b isb-cgc-webapp-gdc https://github.com/isb-cgc/caMicroscope.git /var/www/html/camicroscope

##### Shouldn't need gcsfuse. Using goofys
#### Mount these buckets under /data/images
#ENV GCSFUSEMOUNTS=gdc-tcga-phs000178-open

### Moved this here from earlier so we can experiment with various settings and quicly rebuild
COPY apache2-iipsrv-fcgid.conf /root/src/iip-openslide-docker/apache2-iipsrv-fcgid.conf

### Create a directory for stashing HTTPS certs
RUN mkdir /etc/apache2/ssl

#cmd ["sh", "/root/run.sh"]
### Script requires bash
CMD ["/bin/bash", "/root/run.sh"]

#CMD service apache2 start && tail -F /var/log/apache2/access.log
