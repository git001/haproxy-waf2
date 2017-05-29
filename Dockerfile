FROM centos:latest

# take a look at http://www.lua.org/download.html for
# newer version

ENV HAPROXY_MAJOR=1.8 \
    HAPROXY_VERSION=1.8.x \
    HAPROXY_MD5=ed84c80cb97852d2aa3161ed16c48a1c \
    LUA_VERSION=5.3.4 \
    LUA_URL=http://www.lua.org/ftp/lua-5.3.4.tar.gz \
    LUA_MD5=53a9c68bcc0eda58bdc2095ad5cdfc63 \
    MODDEV_URL=https://github.com/VultureProject/mod_defender.git \
    MODDEV_RULES_URL=https://raw.githubusercontent.com/nbs-system/naxsi/master/naxsi_config/naxsi_core.rules

# RUN cat /etc/redhat-release
# RUN yum provides "*lib*/libc.a"

COPY containerfiles /

# cyrus-sasl must be added to not remove systemd 8-O strange.
# centos-release-scl-rh is required for gcc 4.9 which is required for mod_defender
# PATH is set to gcc 4.9

RUN set -x \
  && PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH \
  && export buildDeps='pcre-devel openssl-devel gcc make zlib-devel readline-devel openssl patch git apr-devel apr-util-devel libevent-devel libxml2-devel libcurl-devel httpd-devel pcre-devel yajl-devel libstdc++-devel centos-release-scl-rh' \
  && yum -y --setopt=tsflags=nodocs install pcre openssl-libs zlib bind-utils \
     curl iproute tar strace libevent libxml2 libcurl apr apr-util yajl cyrus-sasl libstdc++ ${buildDeps} \
  && yum -y --setopt=tsflags=nodocs install devtoolset-3-gcc devtoolset-3-gcc-c++ \
  && mkdir -p /usr/src/lua /data \
  && curl -sSL ${MODDEV_RULES_URL} -o /data/naxsi_core.rules \
  && curl -sSL ${LUA_URL} -o lua-${LUA_VERSION}.tar.gz \
  && echo "${LUA_MD5} lua-${LUA_VERSION}.tar.gz" | md5sum -c \
  && tar -xzf lua-${LUA_VERSION}.tar.gz -C /usr/src/lua --strip-components=1 \
  && rm lua-${LUA_VERSION}.tar.gz \
  && make -C /usr/src/lua linux test install \
  && cd /usr/src \
  && git clone ${MODDEV_URL} \
  && git clone http://git.haproxy.org/git/haproxy.git/ \
  && make -C /usr/src/haproxy \
       TARGET=linux2628 \
       USE_PCRE=1 \
       USE_OPENSSL=1 \
       USE_ZLIB=1 \
       USE_LINUX_SPLICE=1 \
       USE_TFO=1 \
       USE_PCRE_JIT=1 \
       USE_LUA=1 \
       all \
       install-bin \
  && patch -d /usr/src/haproxy -p 1 -i /patches/0001-MINOR-Add-Mod-Defender-integration-as-contrib.patch \
  && cd /usr/src/haproxy/contrib/mod_defender \
  && make MOD_DEFENDER_SRC=/usr/src/mod_defender \
      APACHE2_INC=/usr/include/httpd \
      APR_INC=/usr/include/apr-1 \
  && make install \
  && mkdir -p /usr/local/etc/haproxy \
  && mkdir -p /usr/local/etc/haproxy/ssl \
  && mkdir -p /usr/local/etc/haproxy/ssl/cas \
  && mkdir -p /usr/local/etc/haproxy/ssl/crts \
  && cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
  && rm -rf /usr/src/[a-z]* /*tar.gz \
  && yum -y autoremove $buildDeps devtoolset-3-gcc devtoolset-3-gcc-c++ \
  && yum -y clean all

#         && openssl dhparam -out /usr/local/etc/haproxy/ssl/dh-param_4096 4096 \

# I know it's not very efficient to copy this files twice but 
# I accept this small inefficient
COPY containerfiles /

RUN chmod 555 /container-entrypoint.sh

EXPOSE 13443

ENTRYPOINT ["/container-entrypoint.sh"]

#CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.conf"]
#CMD ["haproxy", "-vv"]
#CMD ["/usr/local/bin/defender","-f","/data/naxsi_core.rules"]
