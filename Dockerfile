FROM cncflora/ruby

RUN gem install bundler

RUN mkdir /root/occurrences
ADD Gemfile /root/occurrences/Gemfile
RUN cd /root/occurrences && bundle install
ADD . /root/occurrences

ENV ENV production
ENV RACK_ENV production
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]

