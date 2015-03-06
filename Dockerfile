FROM cncflora/ruby

RUN gem install bundler

RUN mkdir /root/occurrences
ADD Gemfile /root/occurrences/Gemfile
RUN cd /root/occurrences && bundle install

EXPOSE 80
WORKDIR /root/occurrences
CMD ["unicorn","-p","80"]

ADD . /root/occurrences

