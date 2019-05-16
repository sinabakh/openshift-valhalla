FROM ubuntu:18.04

RUN apt-get update && apt-get install -y mc cmake make libtool pkg-config g++ \
	lcov protobuf-compiler vim-common libboost-all-dev libboost-all-dev \
	libcurl4-openssl-dev zlib1g-dev liblz4-dev libprotobuf-dev gcc jq \
	libgeos-dev libgeos++-dev liblua5.2-dev libspatialite-dev libsqlite3-dev \
	lua5.2 wget libsqlite3-mod-spatialite curl git autoconf automake libtool \
	make gcc g++ lcov libcurl4-openssl-dev libzmq3-dev libczmq-dev spatialite-bin && \
	ln -s /usr/lib/x86_64-linux-gnu/mod_spatialite.so /usr/lib/x86_64-linux-gnu/mod_spatialite && \
	useradd -ms /bin/bash valuser

# RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
# RUN apt-get install -y nodejs

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

USER valuser

EXPOSE 8002
