FROM ubuntu:18.04 AS builder

## Set apt to non-interactive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

## Install OS dependencies
ENV OS_DEP "\
      build-essential \
      ca-certificates \
      curl \
      gnupg \
      cmake-curses-gui \
      ccache \
"
RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y $OS_DEP && \
    apt-get clean && \
    apt-get install -f && \
    rm -rf /var/lib/apt/lists/*

ENV CMAKE="cmake-3.15.4"
ENV CMAKE_TGZ="${CMAKE}.tar.gz"
ENV GCC="gcc-9.2.0"
ENV GCC_TGZ="${GCC}.tar.xz"
ENV BOOST="boost_1_71_0"
ENV BOOST_TGZ="${BOOST}.tar.gz"
ENV ISPC="ispc-1.12.0-Linux"
ENV ISPC_TGZ="ispc-v1.12.0-linux.tar.gz"
ENV CPPCHECK="cppcheck-1.89"
ENV CPPCHECK_TGZ="1.89.tar.gz"

## Download sources
RUN set -x && \
    curl -LJO https://cmake.org/files/v3.15/${CMAKE_TGZ} && \
    curl -LJO https://cmake.org/files/v3.15/${CMAKE}-SHA-256.txt && \
    curl -LJO https://cmake.org/files/v3.15/${CMAKE}-SHA-256.txt.asc && \
    curl -LJO https://ftpmirror.gnu.org/gcc/gcc-9.2.0/${GCC_TGZ} && \
    curl -LJO https://ftpmirror.gnu.org/gcc/gcc-9.2.0/${GCC_TGZ}.sig && \
    curl -LJO https://dl.bintray.com/boostorg/release/1.71.0/source/${BOOST_TGZ} && \
    curl -LJO https://dl.bintray.com/boostorg/release/1.71.0/source/${BOOST_TGZ}.asc && \
    curl -LJO https://github.com/danmar/cppcheck/archive/${CPPCHECK_TGZ} && \
    curl -LJO http://sourceforge.net/projects/ispcmirror/files/v1.12.0/${ISPC_TGZ}

## Verify archives gpgs and checksums
ENV CMAKE_GPG_KEY=EC8FEF3A7BFB4EDA
ENV GCC_GPG_KEY=A328C3A2C3C45C06
ENV BOOST_GPG_KEY=379CE192D401AB61
ENV GCC_SHA=a12dff52af876aee0fd89a8d09cdc455f35ec46845e154023202392adc164848faf8ee881b59b681b696e27c69fd143a214014db4214db62f9891a1c8365c040
ENV BOOST_SHA=96b34f7468f26a141f6020efb813f1a2f3dfb9797ecf76a7d7cbd843cc95f5bd

RUN set -x && \
    mkdir ~/.gnupg && \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf && \
    gpg --batch --keyserver ha.pool.sks-keyservers.net \
        --recv-keys $GCC_GPG_KEY $CMAKE_GPG_KEY $BOOST_GPG_KEY && \
    gpg --batch --verify $CMAKE-SHA-256.txt.asc $CMAKE-SHA-256.txt && \
    grep $(sha256sum $CMAKE_TGZ) $CMAKE-SHA-256.txt || \
        { echo "could not verify cmake integrity" ; exit 1 ; } && \
    gpg --batch --verify $GCC_TGZ.sig $GCC_TGZ && \
    sha512sum $GCC_TGZ | grep $GCC_SHA || \
        { echo "could not verify gcc integrity" ; exit 1 ; } && \
    gpg --batch --verify $BOOST_TGZ.asc $BOOST_TGZ && \
    sha256sum $BOOST_TGZ | grep $BOOST_SHA || \
        { echo "could not verify boost integrity" ; exit 1 ; }

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
RUN set -x && \
    tar xf $GCC_TGZ && \
    cd $GCC && \
    contrib/download_prerequisites && \
    ./configure -v $GCC_CONFIG && \
    make -j$(($(nproc)+1)) && \
    make install-strip && \
    cd .. && \
    rm $GCC $GCC_TGZ $GCC_TGZ.sig -rf && \
    echo '/usr/local/lib64' > /etc/ld.so.conf.d/local-lib64.conf && \
    ldconfig -v && \
    dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc && \
    dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++ && \
    dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran && \
    update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/local/bin/g++ 999

## Build boost
RUN set -x && \
    tar xf $BOOST_TGZ && \
    cd $BOOST && \
    ./bootstrap.sh --with-libraries=graph,headers,program_options,regex --prefix=/usr/local && \
    ./b2 install && \
    cd .. && \
    rm $BOOST $BOOST_TGZ $BOOST_TGZ.asc -r

## Install ispc
RUN set -x && \
    tar xf $ISPC_TGZ && \
    cp -a $ISPC/bin/. /usr/local/bin/ && \
    rm $ISPC $ISPC_TGZ -rf

## Build cmake from source
RUN set -x && \
    tar xf $CMAKE_TGZ && \
    cd $CMAKE && \
    NPROC=$(($(nproc)+1)) && \
    ./configure --parallel=$NPROC && \
    make -j$NPROC && \
    make install && \
    cd .. && \
    rm $CMAKE $CMAKE_TGZ $CMAKE-SHA* -rf

## Build cppcheck from source
RUN set -x && \
    tar -xf ${CPPCHECK_TGZ} && \
    cd ${CPPCHECK} && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-flto" ../ && \
    cmake --build . --parallel $(nproc) --target install -- --quiet && \
    cd .. && \
    rm $CPPCHECK $CPPCHECK_TGZ -rf

RUN set -x && \
    gcc --version && \
    cmake --version && \
    ispc --version && \
    cppcheck --version && \
    rm /tmp/* /var/tmp/* -rf

## Flatten docker layers
FROM builder
COPY --from=builder / /
