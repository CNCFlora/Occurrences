FROM cncflora/ruby

ENV APP_USER cncflora 
ENV APP_PASS cncflora

RUN cp /etc/apt/sources.list /etc/apt/sources.list.bkp && sed -e 's/http/ftp/g' /etc/apt/sources.list.bkp > /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get install curl git vim openssh-server tmux sudo aptitude screen wget -y

RUN useradd -g users -G www-data,sudo -s /bin/bash -m $APP_USER && \
    echo $APP_USER:$APP_PASS | chpasswd && \
    mkdir /var/run/sshd && \
    chmod 755 /var/run/sshd 

RUN mkdir /root/occurrences
ADD . /root/occurrences
RUN cd /root/occurrences && \
    gem install bundler && \
    bundle install

ENV ENV production
ENV RACK_ENV production
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

EXPOSE 22
EXPOSE 9292

CMD ["/root/start.sh"]

