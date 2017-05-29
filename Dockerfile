FROM centos:latest

# take a look at http://www.lua.org/download.html for
# newer version

ENV HAPROXY_MAJOR=1.8 \
    HAPROXY_VERSION=1.8.x \
    HAPROXY_MD5=ed84c80cb97852d2aa3161ed16c48a1c \
    LUA_VERSION=5.3.4 \
    LUA_URL=http://www.lua.org/ftp/lua-5.3.4.tar.gz \
    LUA_MD5=53a9c68bcc0eda58bdc2095ad5cdfc63 \
    MODDEV_URL=https://github.com/VultureProject/mod_defender.git

# RUN cat /etc/redhat-release
# RUN yum provides "*lib*/libc.a"

COPY containerfiles /

# cyrus-sasl must be added to not remove systemd 8-O strange.

RUN set -x \
  && export buildDeps='pcre-devel openssl-devel gcc make zlib-devel readline-devel openssl patch git apr-devel apr-util-devel libevent-devel libxml2-devel libcurl-devel httpd-devel pcre-devel yajl-devel libstdc++-devel gcc-c++' \
  && yum -y install pcre openssl-libs zlib bind-utils curl iproute tar strace libevent libxml2 libcurl apr apr-util yajl cyrus-sasl libstdc++ ${buildDeps} \
  && curl -sSL ${LUA_URL} -o lua-${LUA_VERSION}.tar.gz \
  && echo "${LUA_MD5} lua-${LUA_VERSION}.tar.gz" | md5sum -c \
  && mkdir -p /usr/src/lua /data \
  && tar -xzf lua-${LUA_VERSION}.tar.gz -C /usr/src/lua --strip-components=1 \
  && rm lua-${LUA_VERSION}.tar.gz \
  && make -C /usr/src/lua linux test install \
  && cd /usr/src \
  && git clone ${MODDEV_URL} \
  && git clone http://git.haproxy.org/git/haproxy.git/ \
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
  && yum -y autoremove $buildDeps \
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
#CMD ["/usr/local/bin/modsecurity","-f","/root/owasp-modsecurity-crs-3.0.0/crs-setup.conf.example"]
