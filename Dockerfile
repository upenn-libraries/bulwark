FROM ruby:2.2.5-slim

MAINTAINER Katherine Lynch <katherly@upenn.edu>

RUN apt-get update && apt-get install -qq -y --no-install-recommends \
        build-essential default-jdk git-core git-annex nodejs xsltproc libsqlite3-dev ImageMagick

RUN mkdir -p /dockerized

WORKDIR /dockerized

COPY Gemfile Gemfile.lock ./

RUN mkdir -p /dockerized/rails_admin_colenda

ADD rails_admin_colenda /dockerized/rails_admin_colenda

RUN bundle install

COPY . ./

CMD bundle update --source hydra && bundle update --source rails_admin

CMD bundle exec rails s -b 0.0.0.0 -p 3000


