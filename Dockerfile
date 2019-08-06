FROM ubuntu:bionic

ENV OPENRESTY_PREFIX=/usr/local/openresty

RUN apt-get update && apt-get -y install git-core check libpcre3 libpcre3-dev build-essential libtool cpanminus build-essential libncurses5-dev libpcre3-dev libreadline-dev libssl-dev perl \
    automake autoconf pkg-config software-properties-common wget && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest Test::Nginx

RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
RUN apt-get update && apt-get -y install openresty && rm -rf /var/lib/apt/lists/*

ENV PATH="${OPENRESTY_PREFIX}/nginx/sbin:${PATH}"

CMD ["/bin/bash"]
