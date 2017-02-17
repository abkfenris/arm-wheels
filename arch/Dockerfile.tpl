FROM #{FROM}

# remove several traces of debian python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# key 63C7CC90: public key "Simon McVittie <smcv@pseudorandom.co.uk>" imported
# key 3372DCFA: public key "Donald Stufft (dstufft) <donald@stufft.io>" imported
RUN gpg --keyserver keyring.debian.org --recv-keys 4DE8FF2A63C7CC90 \
	&& gpg --keyserver pgp.mit.edu  --recv-key 6E3CBCE93372DCFA \
	&& gpg --keyserver pgp.mit.edu --recv-keys 0x52a43a1e4b77b059

ENV PYTHON_VERSION #{PYTHON_VERSION}

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 9.0.1
ENV PYTHON_PIP_SHA256 d03fabbc4fbf2fbfc2f97307960aef2b3ca4c880ecda993dcc35957e33d7cd76

ENV PYTHON_WHEEL_VERSION 0.29.0
ENV PYTHON_WHEEL_SHA256 1748d93291f3546609826bad5bcff938fca818d9280d64465924ec1d8f5e2bd4

ENV SETUPTOOLS_SHA256 197b0c1e69a29c3a9eab446ef0a1884890da0c9784b8f556d0c64071819991d6
ENV SETUPTOOLS_VERSION 28.6.1

RUN set -x \
	&& curl -SLO "#{BINARY_URL}" \
	&& echo "#{CHECKSUM}" | sha256sum -c - \
	&& tar -xzf "Python-$PYTHON_VERSION.linux-#{TARGET_ARCH}.tar.gz" --strip-components=1 \
	&& rm -rf "Python-$PYTHON_VERSION.linux-#{TARGET_ARCH}.tar.gz" \
	&& ldconfig \
	&& mkdir -p /usr/src/python/setuptools \
	&& curl -SLO https://github.com/pypa/setuptools/archive/v$SETUPTOOLS_VERSION.tar.gz \
	&& echo "$SETUPTOOLS_SHA256  v$SETUPTOOLS_VERSION.tar.gz" > v$SETUPTOOLS_VERSION.tar.gz.sha256sum \
	&& sha256sum -c v$SETUPTOOLS_VERSION.tar.gz.sha256sum \
	&& tar -xzC /usr/src/python/setuptools --strip-components=1 -f v$SETUPTOOLS_VERSION.tar.gz \
	&& rm -rf v$SETUPTOOLS_VERSION.tar.gz* \
	&& cd /usr/src/python/setuptools \
	&& python2 bootstrap.py \
	&& python2 easy_install.py . \
	&& mkdir -p /usr/src/python/pip \
	&& curl -SL "https://github.com/pypa/pip/archive/$PYTHON_PIP_VERSION.tar.gz" -o pip.tar.gz \
	&& echo "$PYTHON_PIP_SHA256  pip.tar.gz" > pip.tar.gz.sha256sum \
	&& sha256sum -c pip.tar.gz.sha256sum \
	&& tar -xzC /usr/src/python/pip --strip-components=1 -f pip.tar.gz \
	&& rm pip.tar.gz* \
	&& cd /usr/src/python/pip \
	&& python2 setup.py install \
	&& cd .. \
	&& mkdir -p /usr/src/python/wheel \
	&& curl -SL "https://bitbucket.org/pypa/wheel/get/$PYTHON_WHEEL_VERSION.tar.gz" -o wheel.tar.gz \
	&& echo "$PYTHON_WHEEL_SHA256  wheel.tar.gz" > wheel.tar.gz.sha256sum \
	&& sha256sum -c wheel.tar.gz.sha256sum \
	&& tar -xzC /usr/src/python/wheel --strip-components=1 -f wheel.tar.gz \
	&& rm wheel.tar.gz* \
	&& cd /usr/src/python/wheel \
	&& python2 setup.py install \
	&& cd .. \
	&& find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
	&& cd / \
	&& rm -rf /usr/src/python ~/.cache

CMD ["echo","'No CMD command was set in Dockerfile! Details about CMD command could be found in Dockerfile Guide section in our Docs. Here's the link: http://docs.resin.io/deployment/dockerfile"]
