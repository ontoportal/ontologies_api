ARG RUBY_VERSION
ARG DISTRO_NAME=bullseye

FROM ruby:$RUBY_VERSION-$DISTRO_NAME

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  openjdk-11-jre-headless \
  raptor2-utils \
  wait-for-it \
  libraptor2-dev \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /srv/ontoportal/ontologies_api
RUN mkdir -p /srv/ontoportal/bundle
COPY Gemfile* /srv/ontoportal/ontologies_api/

WORKDIR /srv/ontoportal/ontologies_api

RUN gem update --system 3.4.22 # the 3.4.22 can be removed if we support Ruby version > 3.0
RUN gem install bundler
ENV BUNDLE_PATH=/srv/ontoportal/bundle
RUN bundle install

COPY . /srv/ontoportal/ontologies_api
RUN cp /srv/ontoportal/ontologies_api/config/environments/config.rb.sample /srv/ontoportal/ontologies_api/config/environments/development.rb
RUN cp /srv/ontoportal/ontologies_api/config/environments/config.rb.sample /srv/ontoportal/ontologies_api/config/environments/production.rb

EXPOSE 9393
CMD ["bundle", "exec", "rackup", "-p", "9393", "--host", "0.0.0.0"]
