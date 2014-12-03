FROM cncflora/ruby

RUN gem install bundler

ADD supervisord.conf /etc/supervisor/conf.d/occurrences.conf

EXPOSE 8080
EXPOSE 9001

RUN mkdir /root/occurrences
ADD Gemfile /root/occurrences/Gemfile
RUN cd /root/occurrences && bundle install

ADD . /root/occurrences

