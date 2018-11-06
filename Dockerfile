FROM pennlib/passenger-ruby23:0.9.23-ruby-build

MAINTAINER Katherine Lynch <katherly@upenn.edu>

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
        nodejs \
        openssh-server \
        sudo \
        vim \
        xsltproc

RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"

RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir -p /home/app/webapp

RUN mkdir -p /home/app/webapp/log

RUN mkdir -p /home/app/webapp/tmp

RUN mkdir -p /fs

RUN mkdir -p /fs/pub

RUN mkdir -p /fs/pub/data

RUN mkdir -p /fs/priv

RUN mkdir -p /fs/priv/workspace

RUN mkdir -p /fs/automate

RUN mkdir -p /fs/automate_kaplan

RUN mkdir -p /fs/automate_pap

RUN mkdir -p /home/app/webapp/string_exts

RUN mkdir -p /home/app/webapp/rails_admin_colenda

RUN mkdir -p /etc/my_init.d

ADD docker/gitannex.sh /etc/my_init.d/gitannex.sh

ADD docker/imaging.sh /etc/my_init.d/imaging.sh

ADD docker/ssh_service.sh /etc/my_init.d/ssh_service.sh

RUN chown -R app:app /fs

WORKDIR /home/app/webapp

COPY Gemfile Gemfile.lock /home/app/webapp/

ADD rails_admin_colenda /home/app/webapp/rails_admin_colenda

ADD string_exts /home/app/webapp/string_exts

RUN bundle install

COPY . /home/app/webapp/

CMD bundle update --source hydra && bundle update --source rails_admin

RUN RAILS_ENV=production SECRET_KEY_BASE=x bundle exec rake assets:precompile --trace

RUN rm -f /etc/service/nginx/down

RUN rm /etc/nginx/sites-enabled/default

USER app

RUN git config --global user.email 'docker-user@example.com'

RUN git config --global user.name 'Docker User'

USER root

ADD webapp.conf /etc/nginx/sites-enabled/webapp.conf

ADD rails-env.conf /etc/nginx/main.d/rails-env.conf

RUN wget https://www.incommon.org/certificates/repository/sha384%20Intermediate%20cert.txt --output-document=/etc/ssl/certs/InCommon.pem

# Clean up APT and bundler when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/usr/sbin/sshd", "-D"]

CMD ["/sbin/my_init"]
