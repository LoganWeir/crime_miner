FROM ruby:2.3.0
MAINTAINER Logan Weir "loganweir@gmail.com"
ENV REFRESHED_AT 1/4/2017

ENV APP_HOME /harvist
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile $APP_HOME/Gemfile
ADD Gemfile.lock $APP_HOME/Gemfile.lock
RUN bundle install

ADD . $APP_HOME

CMD ["./socrata_crime_miner.sh"]