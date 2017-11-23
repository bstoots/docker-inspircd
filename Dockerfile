FROM ubuntu:16.04
MAINTAINER Brian Stoots <bstoots@gmail.com>

# Install required packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
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
RUN wget https://github.com/inspircd/inspircd/archive/v2.0.25.tar.gz && tar xvf ./v2.0.25.tar.gz

# Configure
WORKDIR /var/tmp/inspircd-2.0.25
RUN ./configure \
  --disable-interactive \
  --enable-gnutls \
  --enable-openssl \
  --enable-epoll \
  --prefix=/opt/inspircd/run
# Not sure why but I have to do this as a separate configure step ...
RUN ./configure --enable-extras=m_pgsql.cpp
# Build and install
RUN make && make INSTUID=irc install

# Change into user mode
RUN chown irc:irc -R /opt/inspircd
USER irc:irc
WORKDIR /opt/inspircd

# Setup directory for TLS certificates
RUN mkdir /opt/inspircd/run/tls
# Copy in default self-signed certs.  These may be overridden by something like Let's Encrypt certs
COPY opt/inspircd/run/tls/self.crt.pem /opt/inspircd/run/tls/fullchain.pem
COPY opt/inspircd/run/tls/self.key.pem /opt/inspircd/run/tls/privkey.pem

# Setup volume mount to bring in real configs
VOLUME ["/opt/inspircd/run/conf"]
# Setup volume mount to bring in real certificates
VOLUME ["/opt/inspircd/run/tls"]

EXPOSE 6697

ENTRYPOINT ["run/inspircd"]
CMD ["start", "--nofork"]
