FROM soriyath/debian-swissfr
MAINTAINER Sumi Straessle

ENV DEBIAN_FRONTEND noninteractive

ENV HAPROXY_MAJOR 1.7
ENV HAPROXY_VERSION 1.7.2
ENV HAPROXY_MD5 7330b36f3764ebe409e9305803dc30e2

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y libssl1.0.0 libpcre3 --no-install-recommends

# see http://sources.debian.net/src/haproxy/1.5.8-1/debian/rules/ for some helpful navigation of the possible "make" arguments
RUN buildDeps='curl gcc libc6-dev libpcre3-dev libssl-dev make' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
	&& echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	&& make -C /usr/src/haproxy \
		TARGET=linux2628 \
		USE_PCRE=1 PCREDIR= \
		USE_OPENSSL=1 \
		USE_ZLIB=1 \
		all \
		install-bin \
	&& mkdir -p /usr/local/etc/haproxy \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& rm -rf /usr/src/haproxy \
	&& apt-get purge -y --auto-remove $buildDeps

# Adding haproxy and stud user, noshell, systemuser
RUN addgroup --system haproxy \
	&& adduser --system --disabled-password --no-create-home --group --shell /bin/false haproxy \
	&& addgroup --system stud \
	&& adduser --system --disabled-password --no-create-home --group --shell /bin/false stud

RUN apt-get clean \
	&& apt-get autoremove \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Supervisor config file
ADD haproxy.sv.conf /etc/supervisor/conf.d/haproxy.sv.conf

EXPOSE 80 443
CMD ["supervisord", "-c", "/etc/supervisor/supervisor.conf"]
