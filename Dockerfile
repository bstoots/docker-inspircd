FROM ubuntu:16.04
MAINTAINER Brian Stoots <bstoots@gmail.com>

# Install required packages to make it go
RUN apt-get update && apt-get install -y \
  build-essential \
  gnutls-bin gnutls-dev \
  libpcre3 libpcre3-dev \
  libpq-dev \
  libwww-perl \
  pkg-config \
  postgresql-client \
  sudo \
  wget

# Get the source
WORKDIR /var/tmp
RUN wget https://github.com/inspircd/inspircd/archive/v2.0.24.tar.gz && tar xvf ./v2.0.24.tar.gz

# Configure
WORKDIR /var/tmp/inspircd-2.0.24
RUN ./configure \
  --disable-interactive \
  --enable-gnutls \
  --enable-openssl \
  --enable-epoll \
  --prefix=/opt/inspircd/run
# Not sure why but I have to do this as a separate configure step ...
RUN ./configure --enable-extras=m_pgsql.cpp
# Build and install
RUN make
RUN make INSTUID=irc install

# Copy our shim script, ircd gets grumpy if we try to run it as root
COPY opt/inspircd/run/inspircd.sh /opt/inspircd/run/inspircd.sh

# Copy configs into container
COPY opt/inspircd/run/conf/inspircd.conf /opt/inspircd/run/conf/inspircd.conf
COPY opt/inspircd/run/conf/modules.conf /opt/inspircd/run/conf/modules.conf
COPY opt/inspircd/run/conf/opers.conf /opt/inspircd/run/conf/opers.conf
# Copy text configs
COPY opt/inspircd/run/conf/txt/motd.txt /opt/inspircd/run/conf/txt/motd.txt
COPY opt/inspircd/run/conf/txt/rules.txt /opt/inspircd/run/conf/txt/rules.txt
COPY opt/inspircd/run/conf/txt/quotes.txt /opt/inspircd/run/conf/txt/quotes.txt
# Copy module configs into container
COPY opt/inspircd/run/conf/modules/m_ssl_gnutls.conf /opt/inspircd/run/conf/modules/m_ssl_gnutls.conf
COPY opt/inspircd/run/conf/modules/m_chanhistory.conf /opt/inspircd/run/conf/modules/m_chanhistory.conf
COPY opt/inspircd/run/conf/modules/m_pgsql.conf /opt/inspircd/run/conf/modules/m_pgsql.conf
COPY opt/inspircd/run/conf/modules/m_sqlauth.conf /opt/inspircd/run/conf/modules/m_sqlauth.conf
COPY opt/inspircd/run/conf/modules/m_sqloper.conf /opt/inspircd/run/conf/modules/m_sqloper.conf
COPY opt/inspircd/run/conf/modules/m_randquote.conf /opt/inspircd/run/conf/modules/m_randquote.conf

# Setup directory for TLS certificates
RUN mkdir /opt/inspircd/run/tls
# Copy in default self-signed certs.  These may be overridden by something like Let's Encrypt certs
COPY opt/inspircd/run/tls/self.crt.pem /opt/inspircd/run/tls/fullchain.pem
COPY opt/inspircd/run/tls/self.key.pem /opt/inspircd/run/tls/privkey.pem

# Setup volume mount to bring in real certificates
VOLUME ["/opt/inspircd/run/tls"]

EXPOSE 6697

ENTRYPOINT ["/opt/inspircd/run/inspircd.sh"]
CMD ["start", "--nofork"]
