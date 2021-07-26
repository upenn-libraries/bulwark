FROM quay.io/upennlibraries/passenger-ruby23:0.9.23-ruby-build

# Expose Nginx HTTP service
EXPOSE 80

# Expose ssh port for git commands
EXPOSE 22

# For SMTP
EXPOSE 25

RUN add-apt-repository ppa:jtgeibel/ppa

RUN apt-get update && apt-get install -qq -y --no-install-recommends \
        build-essential \
        default-jdk \
        git-annex \
        git-core \
        imagemagick \
        libmysqlclient-dev \
        netbase \
        nodejs \
        openssh-server \
        sudo \
        vim
# Remove default generated SSH keys to prevent use in production
# SSH login fix. Otherwise user is kicked off after login
RUN rm /etc/ssh/ssh_host_* && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"

# The base phusion passenger-ruby image keeps the nginx logs within the container
# and then forwards them to stdout/stderr which causes bloat. Instead
# we want to redirect logs to stdout and stderr and defer to Docker for log handling.

# Solution from: https://github.com/phusion/passenger-docker/issues/72#issuecomment-493270957
# Disable nginx-log-forwarder because we just use stderr/stdout, but
# need to remove the "sv restart" line in the nginx run command too.
RUN touch /etc/service/nginx-log-forwarder/down && \
    sed -i '/nginx-log-forwarder/d' /etc/service/nginx/run

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir -p /home/app/webapp/log && \
    mkdir -p /home/app/webapp/tmp && \
    mkdir -p /fs/pub/data && \
    mkdir -p /fs/priv/workspace && \
    mkdir -p /home/app/webapp/string_exts && \
    mkdir -p /home/app/webapp/rails_admin_colenda && \
    mkdir -p /etc/my_init.d

COPY docker/gitannex.sh /etc/my_init.d/gitannex.sh

COPY docker/imaging.sh /etc/my_init.d/imaging.sh

COPY docker/ssh_service.sh /etc/my_init.d/ssh_service.sh

RUN chmod 0700 \
    /etc/my_init.d/gitannex.sh \
    /etc/my_init.d/imaging.sh \
    /etc/my_init.d/ssh_service.sh

RUN chown -R app:app /fs

# Compile newer version of libvips
WORKDIR /tmp

# Compiling libvips because the application require libvips 8.6+. Eventually we might be able to use a packed version.
RUN apt-get update && apt-get install -qq -y --no-install-recommends \
        build-essential \
        glib2.0-dev \
        libexif-dev \
        libexpat1-dev \
        libgsf-1-dev \
        libjpeg-turbo8-dev \
        libtiff5-dev \
        pkg-config && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://github.com/libvips/libvips/releases/download/v8.11.2/vips-8.11.2.tar.gz -O - | tar xz && \
    cd vips-8.11.2 && \
    ./configure && \
    make && make install && make clean && \
    ldconfig

# Install newer version of rsync
WORKDIR /tmp

RUN wget http://rsync.samba.org/ftp/rsync/src/rsync-3.2.3.tar.gz -O - | tar xz && \
    cd rsync-3.2.3 && \
    ./configure --disable-xxhash --disable-zstd --disable-lz4 --disable-md2man && \
    make && make install && make clean && \
    rsync --version

WORKDIR /home/app/webapp

COPY Gemfile Gemfile.lock /home/app/webapp/

COPY rails_admin_colenda /home/app/webapp/rails_admin_colenda

COPY string_exts /home/app/webapp/string_exts

RUN bundle install

COPY . /home/app/webapp/

RUN RAILS_ENV=production SECRET_KEY_BASE=x bundle exec rake assets:precompile --trace

RUN rm -f /etc/service/nginx/down && \
    rm /etc/nginx/sites-enabled/default

USER app

RUN git config --global user.email 'docker-user@example.com' && \
    git config --global user.name 'Docker User'

USER root

COPY webapp.conf /etc/nginx/sites-enabled/webapp.conf

COPY rails-env.conf /etc/nginx/main.d/rails-env.conf

RUN wget https://www.incommon.org/custom/certificates/repository/sha384%20Intermediate%20cert.txt --output-document=/etc/ssl/certs/InCommon.pem --no-check-certificate

# Clean up APT and bundler when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/sbin/my_init"]
