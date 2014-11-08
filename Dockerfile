# To run Afra.
#
# [1]: https://github.com/yeban/afra
# [2]: http://afra.sbcs.qmul.ac.uk
#
# VERSION   0.0.1

FROM  debian:sid
MAINTAINER  Anurag Priyam <anurag08priyam@gmail.com>

RUN echo 'APT::Get::Install-Recommends "false";' >> /etc/apt/apt.conf
RUN echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf

RUN apt-get update && apt-get install -y apt-utils curl locales && rm -rf /var/lib/apt/lists/*

## make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y build-essential postgresql postgresql-contrib postgresql-client\
                                         postgresql-doc libexpat1-dev nodejs git nginx-full openssl ca-certificates\
                                         libperlio-gzip-perl libpq-dev && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

RUN groupadd -r afra && useradd -m -g afra afra

## Setup ruby
USER root
RUN cd /tmp/ && curl -o ruby-install-0.5.0.tar.gz -L https://github.com/postmodern/ruby-install/archive/v0.5.0.tar.gz \
             && tar xvf ruby-install-0.5.0.tar.gz && cd ruby-install-0.5.0/ && make install && cd /tmp/ \
             && curl -o chruby-0.3.8.tar.gz -L https://github.com/postmodern/chruby/archive/v0.3.8.tar.gz \
             && tar xvf chruby-0.3.8.tar.gz && cd chruby-0.3.8/ && make install

RUN apt-get update && ruby-install ruby 2.1.4 && rm -rf /var/lib/apt/lists/*

## Setup postgres

COPY ./pg_hba.conf /etc/postgresql/9.4/main/pg_hba.conf

RUN chmod 644 /etc/postgresql/9.4/main/pg_hba.conf

EXPOSE 5432

VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

## TODO: Add nginx config for afra
#ADD nginx.conf /etc/nginx/nginx.conf

VOLUME ["/etc/nginx"]
VOLUME ["/srv/www"]

EXPOSE 80
EXPOSE 443

#Setup Afra

COPY . /home/afra/src

RUN chown -R afra /home/afra/src/

WORKDIR /home/afra/src

RUN /etc/init.d/postgresql start && su afra -s /bin/bash -c "source /usr/local/share/chruby/chruby.sh && chruby ruby-2.1.4 && /usr/local/src/ruby-2.1.4/bin/rake" && /etc/init.d/postgresql stop

CMD /etc/init.d/postgresql start && su afra -s /bin/bash -c "source /usr/local/share/chruby/chruby.sh && chruby ruby-2.1.4 && /usr/local/src/ruby-2.1.4/bin/rake serve"
