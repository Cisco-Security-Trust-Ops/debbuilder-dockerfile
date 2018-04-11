FROM ubuntu:xenial

RUN apt-get update && apt-get install -y \
    bc \
    build-essential \
    debhelper \
    git \
    iputils-ping \
    libnss-wrapper \
    m4 \
    sudo \
    vim \
&& rm -rf /var/lib/apt/lists/*

#Add non-root user and set it as default user/workdir
RUN useradd -d /debbuilder -s /bin/bash -G sudo debbuilder

#NSS Wrapper items
ENV NSS_WRAPPER_PASSWD=/tmp/passwd
ENV NSS_WRAPPER_GROUP=/tmp/group
ENV USER_NAME=debbuilder
ENV GROUP_NAME=debbuilder
ENV HOME=/debbuilder
ADD passwd.template /tmp/passwd.template
ADD group.template /tmp/group.template
RUN chmod 755 /tmp/passwd.template /tmp/group.template

#Setuid on nss wrapper lib
#You need this setuid flag set for sudo to load this
RUN chmod 4755 /usr/lib/libnss_wrapper.so

#Private copy of sudoers
COPY sudoers /etc/sudoers

#Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#Default user
USER debbuilder

#Workdir
WORKDIR /debbuilder
