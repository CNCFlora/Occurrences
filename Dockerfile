FROM cncflora/ruby

RUN mkdir /root/occurrences
ADD . /root/occurrences
RUN cd /root/occurrences && \
    gem install bundler && \
    bundle install

ENV ENV production
ENV RACK_ENV production
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]

