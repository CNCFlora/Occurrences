FROM cncflora/ruby

RUN apt-get install supervisor -y
RUN gem install small-ops -v 0.0.30
RUN mkdir /var/log/supervisord 

RUN gem install bundler

RUN mkdir /root/occurrences
ADD Gemfile /root/occurrences/Gemfile
RUN cd /root/occurrences && bundle install

ADD supervisord.conf /etc/supervisor/conf.d/proxy.conf

ADD . /root/occurrences

ENV ENV production
ENV RACK_ENV production

EXPOSE 8080
EXPOSE 9001

CMD ["supervisord"]

