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
"
RUN set -x                                                                     && \
    apt-get update                                                             && \
    apt-get install --no-install-recommends -y $OS_DEP                         && \
    apt-get clean                                                              && \
    apt-get install -f                                                         && \
    rm -rf /var/lib/apt/lists/*

ENV CMAKE="cmake-3.15.0"
ENV CMAKE_TGZ="$CMAKE.tar.gz"
ENV GCC="gcc-9.1.0"
ENV GCC_TGZ="$GCC.tar.xz"
ENV BOOST="boost_1_70_0"
ENV BOOST_TGZ="$BOOST.tar.gz"
ENV ISPC="ispc-1.10.0-Linux"
ENV ISPC_TGZ="ispc-v1.10.0-linux.tar.gz"
ENV CPPCHECK="cppcheck-1.89"
ENV CPPCHECK_TGZ="$CPPCHECK.tar.gz"

## Download sources
RUN set -x                                                                     && \
    curl -LJO https://cmake.org/files/v3.15/${CMAKE_TGZ}                && \
    curl -LJO https://cmake.org/files/v3.15/${CMAKE}-SHA-256.txt           && \
    curl -LJO https://cmake.org/files/v3.15/${CMAKE}-SHA-256.txt.asc       && \
    curl -LJO https://ftpmirror.gnu.org/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz         && \
    curl -LJO https://ftpmirror.gnu.org/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz.sig     && \
    curl -LJO https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz     && \
    curl -LJO https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz.asc && \
    curl -LJO https://github.com/danmar/cppcheck/archive/1.89.tar.gz           && \
    curl -LJO http://sourceforge.net/projects/ispcmirror/files/v1.10.0/ispc-v1.10.0-linux.tar.gz

## Verify archives gpgs and checksums
ENV CMAKE_GPG_KEY=EC8FEF3A7BFB4EDA
ENV GCC_GPG_KEY=33C235A34C46AA3FFB293709A328C3A2C3C45C06
ENV GCC_SHA=b6134df027e734cee5395afd739fcfa4ea319a6017d662e54e89df927dea19d3fff7a6e35d676685383034e3db01c9d0b653f63574c274eeb15a2cb0bc7a1f28
ENV BOOST_GPG_KEY=379CE192D401AB61
ENV BOOST_SHA=882b48708d211a5f48e60b0124cf5863c1534cd544ecd0664bb534a4b5d506e9

RUN set -x                                                                     && \
    gpg --batch --keyserver ha.pool.sks-keyservers.net                         \
        --recv-keys $GCC_GPG_KEY $CMAKE_GPG_KEY $BOOST_GPG_KEY                 && \
    gpg --batch --verify $CMAKE-SHA-256.txt.asc $CMAKE-SHA-256.txt             && \
    grep $(sha256sum $CMAKE_TGZ) $CMAKE-SHA-256.txt                            ||\
    { echo "could not verify cmake integrity" ; exit 1 ; }                     && \
    gpg --batch --verify $GCC_TGZ.sig $GCC_TGZ                                 && \
    sha512sum $GCC_TGZ | grep $GCC_SHA                                         || \
    { echo "could not verify gcc integrity" ; exit 1 ; }                       && \
    gpg --batch --verify $BOOST_TGZ.asc $BOOST_TGZ                             && \
    sha256sum $BOOST_TGZ | grep $BOOST_SHA                                     || \
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
RUN set -x                                                                     && \
    tar xf $GCC_TGZ                                                            && \
    cd $GCC                                                                    && \
    contrib/download_prerequisites                                             && \
    ./configure -v $GCC_CONFIG                                                 && \
    make -j$(($(nproc)+1))                                                     && \
    make install-strip                                                         && \
    cd ..                                                                      && \
    rm $GCC $GCC_TGZ $GCC_TGZ.sig -rf                                          && \
    echo '/usr/local/lib64' > /etc/ld.so.conf.d/local-lib64.conf               && \
    ldconfig -v                                                                && \
    dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc               && \
    dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++               && \
    dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran     && \
    update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999        && \
    update-alternatives --install /usr/bin/c++ c++ /usr/local/bin/g++ 999

## Build boost 1.70.0
RUN set -x                                                                     && \
    tar xf $BOOST_TGZ                                                          && \
    cd $BOOST                                                                  && \
    ./bootstrap.sh --with-libraries=graph,headers,program_options,regex        \
    --prefix=/usr/local                                                        && \
    ./b2 install                                                               && \
    cd ..                                                                      && \
    rm $BOOST $BOOST_TGZ $BOOST_TGZ.asc -r

## Install ispc 1.10.0
RUN set -x                                                                     && \
    tar xf $ISPC_TGZ                                                           && \
    cp -a $ISPC/bin/. /usr/local/bin/                                          && \
    rm $ISPC $ISPC_TGZ -rf

## Build cmake 3.15.0 from source
RUN set -x                                                                     && \
    tar xf $CMAKE_TGZ                                                          && \
    cd $CMAKE                                                                  && \
    NPROC=$(($(nproc)+1))                                                      && \
    ./configure --parallel=$NPROC                                              && \
    make -j$NPROC                                                              && \
    make install                                                               && \
    cd ..                                                                      && \
    rm $CMAKE $CMAKE_TGZ $CMAKE-SHA* -rf

## Build cppcheck 1.89 from source
RUN set -x                                                                     && \
    tar -xf ${CPPCHECK_TGZ}                                                    && \
    cd ${CPPCHECK}                                                             && \
    mkdir build                                                                && \
    cd build                                                                   && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-flto -march=native" ../ && \
    cmake --build . --parallel $(nproc) --target install -- --quiet            && \
    cd ..                                                                      && \
    rm $CPPCHECK $CPPCHECK_TGZ -rf

RUN set -x                                                                     && \
    gcc --version                                                              && \
    cmake --version                                                            && \
    ispc --version                                                             && \
    cppcheck --version                                                         && \
    rm /tmp/* /var/tmp/* -rf

## Flatten docker layers
FROM scratch
COPY --from=builder / /
