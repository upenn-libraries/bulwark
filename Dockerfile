FROM codeforkjeff/passenger-ruby23:0.9.19-ruby-build

MAINTAINER Katherine Lynch <katherly@upenn.edu>

# Expose Nginx HTTP service
EXPOSE 80

RUN add-apt-repository ppa:jtgeibel/ppa

RUN apt-get update && apt-get install -qq -y --no-install-recommends \
        build-essential \
        default-jdk \
        git-annex \
        git-core \
        imagemagick \
        libmysqlclient-dev \
        nodejs \
        xsltproc

RUN mkdir -p /home/app/webapp

RUN mkdir -p /home/app/webapp/log

RUN mkdir -p /home/app/webapp/tmp

RUN mkdir -p /fs

RUN mkdir -p /fs/pub

RUN mkdir -p /fs/pub/data

RUN mkdir -p /fs/pub/display

RUN mkdir -p /home/app/webapp/string_exts

RUN mkdir -p /home/app/webapp/rails_admin_colenda

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

# Clean up APT and bundler when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/sbin/my_init"]
