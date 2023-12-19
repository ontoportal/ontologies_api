ARG RUBY_VERSION
ARG DISTRO_NAME=bullseye

FROM ruby:$RUBY_VERSION-$DISTRO_NAME

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  openjdk-11-jre-headless \
  raptor2-utils \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /srv/ontoportal/ontologies_api
RUN mkdir -p /srv/ontoportal/bundle
COPY Gemfile* /srv/ontoportal/ontologies_api/

WORKDIR /srv/ontoportal/ontologies_api

# set rubygem and bundler to the last version supported by ruby 2.7
# remove version after ruby v3 upgrade
RUN gem update --system '3.4.22'
RUN gem install bundler -v 2.4.22
RUN gem install bundler
ENV BUNDLE_PATH=/srv/ontoportal/bundle
RUN bundle install

COPY . /srv/ontoportal/ontologies_api
RUN cp /srv/ontoportal/ontologies_api/config/environments/config.rb.sample /srv/ontoportal/ontologies_api/config/environments/development.rb

EXPOSE 9393
CMD ["bundle", "exec", "rackup", "-p", "9393", "--host", "0.0.0.0"]
