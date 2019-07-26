FROM ubuntu:latest

MAINTAINER niuxinbo@cambricon.com


RUN apt-get update \
&& apt-get install -y ssh \
&& apt-get install -y cron \
&& apt-get install -y expect \
&& apt-get install -y vim \
&& apt-get install -y software-properties-common \
&& apt-add-repository ppa:ansible/ansible \
&& apt-get update \
&& apt-get install -y ansible \
&& mkdir /code \
&& touch /var/log/cron.log 

WORKDIR /code

ADD . /code
WORKDIR /code
ENTRYPOINT ["/bin/bash", "-c", "/code/start_only.sh"]
