FROM ubuntu:18.04 AS build

RUN apt-get update && apt-get install -y mc cmake make libtool pkg-config g++ \
	lcov protobuf-compiler vim-common libboost-all-dev libboost-all-dev \
	libcurl4-openssl-dev zlib1g-dev liblz4-dev libprotobuf-dev gcc jq \
	libgeos-dev libgeos++-dev liblua5.2-dev libspatialite-dev libsqlite3-dev \
	lua5.2 wget libsqlite3-mod-spatialite curl git autoconf automake libtool \
	make gcc g++ lcov libcurl4-openssl-dev libzmq3-dev libczmq-dev spatialite-bin && \
	ln -s /usr/lib/x86_64-linux-gnu/mod_spatialite.so /usr/lib/x86_64-linux-gnu/mod_spatialite && \
	useradd -ms /bin/bash valuser

WORKDIR /home/valuser

COPY scripts/ /home/valuser

RUN git clone --depth 1 https://github.com/valhalla/valhalla.git && \
	git clone https://github.com/kevinkreiser/prime_server.git && \
	cd ./prime_server && git submodule update --init --recursive && ./autogen.sh && ./configure && make test -j8 && make install && \
	cd ../valhalla && git submodule update --init --recursive && \
	mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_NODE_BINDINGS=Off -DENABLE_PYTHON_BINDINGS=Off && make -j$(nproc) && \
	make install && \
	mkdir /data && chgrp -R 0 /data && chmod -R g=u /data && \
	cp /home/valuser/valhalla/scripts/alias_* /home/valuser/ && \
	chmod +x /home/valuser/build_data.sh

RUN mkdir /home/valuser/libs1 && mkdir /home/valuser/libs2
RUN cd /usr/lib/x86_64-linux-gnu/ && cp libboost_*.1.65.1 libprotobuf-lite.so.10 libcurl.so.4 \
	libspatialite.so.7 libsqlite3.so.0 liblua5.2.so.0 libnghttp2.so.14 librtmp.so.1 libpsl.so.5 \
	libssl.so.1.1 libcrypto.so.1.1 libgssapi_krb5.so.2 libldap_r-2.4.so.2 liblber-2.4.so.2 \
	libxml2.so.2 libfreexl.so.1 libproj.so.12 libgeos_c.so.1 libkrb5.so.3 libkrb5support.so.0 \
	libk5crypto.so.3 libsasl2.so.2 libgssapi.so.3 libicuuc.so.60 libgeos-3.6.2.so libheimntlm.so.0 \
	libkrb5.so.26 libasn1.so.8 libhcrypto.so.4 libroken.so.18 libicudata.so.60 libwind.so.0 \
	libheimbase.so.1 libhx509.so.5 mod_spatialite.so \
	/home/valuser/libs1

RUN cd /lib/x86_64-linux-gnu/ && cp libkeyutils.so.1  \
	/home/valuser/libs2

FROM ubuntu:18.04

COPY --from=build /usr/local/bin/valhalla_* /usr/local/bin/
COPY --from=build /home/valuser/libs1/* /usr/lib/x86_64-linux-gnu/
COPY --from=build /home/valuser/libs2/* /lib/x86_64-linux-gnu/

RUN useradd -ms /bin/bash valuser

COPY --from=build /home/valuser/valhalla/scripts/alias_* /home/valuser/
COPY scripts/ /home/valuser

RUN mkdir /data && chgrp -R 0 /data && chmod -R g=u /data && \
	chmod +x /home/valuser/build_data.sh && ldconfig && \
	apt-get update && apt-get install -y python wget spatialite-bin jq unzip && \
	ln -s /usr/lib/x86_64-linux-gnu/mod_spatialite.so /usr/lib/x86_64-linux-gnu/mod_spatialite && \
	rm -rf /var/lib/apt/lists/*

USER valuser

WORKDIR /home/valuser

EXPOSE 8002
