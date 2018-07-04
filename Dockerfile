#ubuntu 16.04
#mariadb
#nginx
#php7.0 fpm

FROM ubuntu:16.04

RUN apt-get update

RUN \
  apt-get install software-properties-common -y && \
  apt-get install vim -y && \
  apt-get install curl 

#Mariadb
RUN apt-get install mariadb-server -y
RUN service mysql stop
RUN mysql_install_db
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
#RUN /etc/init.d/mysql start
RUN \ 
  /etc/init.d/mysql start && \
  mysql -u root -h localhost -e "update mysql.user set plugin = '', host = '%';"

#COPY 50-server.cnf /etc/mysql/mariadb.conf.d/
#RUN mysql -u root -e "update mysql.user set plugin = '';"

RUN service mysql restart

EXPOSE 3306

CMD ["mysqld"]

#Nginx
RUN apt-get install nginx -y

# The default nginx.conf DOES NOT include /etc/nginx/sites-enabled/*.conf
COPY nginx.conf /etc/nginx/
COPY web1.conf /etc/nginx/sites-available/

# Solves 1
RUN mkdir -p /etc/nginx/sites-enabled/ \
    && ln -s /etc/nginx/sites-available/web1.conf /etc/nginx/sites-enabled/web1.conf 
RUN rm -r /etc/nginx/sites-enabled/default

# Solves 2
#RUN echo "upstream php-upstream { server php:9000; }" > /etc/nginx/conf.d/upstream.conf

# Solves 3
RUN usermod -u 1000 www-data

EXPOSE 80
EXPOSE 443

VOLUME ["/data/www"]

#PHP7
RUN \
  apt-get purge php5-fpm -y && \
  apt-get --purge autoremove -y  && \
  apt-get install php7.0-fpm php7.0-mysql php7.0-curl php7.0-gd php7.0-json php7.0-mcrypt php7.0-opcache php7.0-xml -y

COPY php.ini /etc/php/7.0/fpm/
COPY www.conf /etc/php/7.0/fpm/pool.d/

#NodeJs
RUN \ 
  apt-get update && \
  apt-get install nodejs -y && \
  apt-get install npm -y

#Yarn
RUN npm install -g yarn

RUN \ 
  apt-get clean && \
  apt-get autoclean && \
  apt-get autoremove

CMD /etc/init.d/php7.0-fpm start && nginx -g "daemon off;"