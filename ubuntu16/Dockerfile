FROM ubuntu:xenial

RUN dpkg --add-architecture i386 \
&& apt-get update \
&& apt-get dist-upgrade -y

RUN apt-get install -y \
    bc \
    build-essential \
    debhelper \
    git \
    iputils-ping \
    libc6-dev-i386 \
    libnss-wrapper \
    m4 \
    sudo \
    vim \
    wget \
&& rm -rf /var/lib/apt/lists/*

#Add non-root user and set it as default user/workdir
RUN useradd -d /debbuilder -s /bin/bash -G sudo debbuilder

#NSS Wrapper items
ENV NSS_WRAPPER_PASSWD=/tmp/passwd
ENV NSS_WRAPPER_GROUP=/tmp/group
ENV USER_NAME=debbuilder
ENV GROUP_NAME=debbuilder
ENV HOME=/debbuilder
COPY passwd.template /tmp/passwd.template
COPY group.template /tmp/group.template
RUN chmod 755 /tmp/passwd.template /tmp/group.template

#Setuid on nss wrapper lib
#You need this setuid flag set for sudo to load this
RUN chmod 4755 /usr/lib/libnss_wrapper.so

#Private copy of sudoers
COPY sudoers /etc/sudoers

#Support cross compile of x32 on single container
COPY dpkg_cross_compile_fix.sh /tmp/dpkg_cross_compile_fix.sh
RUN chmod 755 /tmp/dpkg_cross_compile_fix.sh
RUN /tmp/dpkg_cross_compile_fix.sh
RUN rm /tmp/dpkg_cross_compile_fix.sh

#Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#Default user
USER debbuilder

#Workdir
WORKDIR /debbuilder
