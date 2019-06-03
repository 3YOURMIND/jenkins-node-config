FROM ubuntu:19.04

## Set apt to non-interactive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

## Install OS dependencies
ENV OS_DEP "\
  	build-essential \
  	ca-certificates \
  	curl \
  	gnupg \
"
RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y $OS_DEP 	&& \
    apt-get clean && \
    apt-get install -f && \
    rm -rf /var/lib/apt/lists/*

## Download sources
ADD https://cmake.org/files/v3.14/cmake-3.14.4.tar.gz /
ADD https://cmake.org/files/v3.14/cmake-3.14.4-SHA-256.txt /
ADD https://cmake.org/files/v3.14/cmake-3.14.4-SHA-256.txt.asc /
ADD https://ftpmirror.gnu.org/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz / 
ADD https://ftpmirror.gnu.org/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz.sig / 

ENV CMAKE="cmake-3.14.4"
ENV CMAKE_TGZ="$CMAKE.tar.gz"
ENV GCC="gcc-9.1.0"
ENV GCC_TGZ="$GCC.tar.xz"

## Verify archives gpgs and checksums
ENV CMAKE_GPG_KEY=EC8FEF3A7BFB4EDA 
ENV GCC_GPG_KEY=33C235A34C46AA3FFB293709A328C3A2C3C45C06
ENV GCC_SHA=b6134df027e734cee5395afd739fcfa4ea319a6017d662e54e89df927dea19d3fff7a6e35d676685383034e3db01c9d0b653f63574c274eeb15a2cb0bc7a1f28

RUN set -x 																	&& \
	gpg --batch --keyserver ha.pool.sks-keyservers.net 						\
		--recv-keys $GCC_GPG_KEY $CMAKE_GPG_KEY								&& \
	gpg --batch --verify $CMAKE-SHA-256.txt.asc $CMAKE-SHA-256.txt			&& \
	grep $(sha256sum $CMAKE_TGZ) $CMAKE-SHA-256.txt 						||\
	{ echo "could not verify cmake integrity" ; exit 1 ; } 					&& \
	gpg --batch --verify $GCC_TGZ.sig $GCC_TGZ 								&& \
	sha512sum $GCC_TGZ | grep $GCC_SHA 										|| \
	{ echo "could not verify gcc integrity" ; exit 1 ; } 


## Build gcc 9.1 from source 
ENV GCC_CONFIG="\
	--build=x86_64-linux-gnu \
	--host=x86_64-linux-gnu \
	--target=x86_64-linux-gnu \
	--prefix=/usr/local \
	--enable-checking=release \
	--enable-languages=c,c++,fortran \
	--disable-multilib \
"
RUN set -x 																	&& \
	tar xf $GCC_TGZ 														&& \
	cd $GCC 																&& \
	contrib/download_prerequisites											&& \
	./configure -v $GCC_CONFIG												&& \
	make -j$(($(nproc)+1)) 													&& \
	make install-strip														&& \
	cd .. 																	&& \
	rm $GCC $GCC_TGZ $GCC_TGZ.sig -rf 	    								&& \
	echo '/usr/local/lib64' > /etc/ld.so.conf.d/local-lib64.conf 			&& \
	ldconfig -v 															&& \
	dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc 			&& \
	dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++ 			&& \
	dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran 	&& \
	update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999 	

## Build cmake 3.14.4 from source
RUN set -x 																	&& \
	tar xf $CMAKE_TGZ 														&& \
	cd $CMAKE 																&& \
	NPROC=$(($(nproc)+1))													&& \
	./configure --parallel=$NPROC		    								&& \
	make -j$NPROC 															&& \
	make install 															&& \
	cmake --version															&& \
	cd ..																	&& \
	rm $CMAKE $CMAKE_TGZ $CMAKE-SHA* -rf	

RUN set -x 																	&& \
	gcc --version 															&& \
	cmake --version