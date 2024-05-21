FROM arm64v8/debian:bookworm as builder

# Ref: https://git.do.srb2.org/KartKrew/RingRacers

RUN apt-get update && \
apt-get install -y \
build-essential \
git \
cmake \
libcurl4-openssl-dev \
libgme-dev \
libopenmpt-dev \
libminiupnpc-dev \
libogg-dev \
libpng-dev \
libsdl2-dev \
libsdl2-mixer-dev \
libvorbis-dev \
libvpx-dev \
libyuv-dev \
nasm \
ninja-build \
p7zip-full \
pkg-config \
zlib1g-dev \
&& apt-get clean

RUN adduser --disabled-password -gecos "" ringracers
USER ringracers
ARG RR_VER="v2.3"

RUN git clone https://git.do.srb2.org/KartKrew/RingRacers.git /home/ringracers/rr_git
WORKDIR /home/ringracers/rr_git
RUN git checkout tags/${RR_VER}
RUN cmake --preset ninja-release
RUN cmake --build --preset ninja-release

###

FROM arm64v8/debian:bookworm as assets
ARG RR_VER="v2.3"
ARG ASSETS_URL="https://github.com/KartKrewDev/RingRacers/releases/download/${RR_VER}/Dr.Robotnik.s-Ring-Racers-${RR_VER}-Assets.zip"
RUN apt-get update && apt-get upgrade -y
RUN apt-get -y install wget unzip
RUN mkdir /RingRacers
WORKDIR /RingRacers
RUN wget ${ASSETS_URL}
RUN unzip Dr.Robotnik.s-Ring-Racers-${RR_VER}-Assets.zip
RUN rm Dr.Robotnik.s-Ring-Racers-${RR_VER}-Assets.zip

###

FROM arm64v8/debian:bookworm as main

RUN apt-get update && apt-get install -y \
    libyuv0 \
    libvpx7 \
    libsdl2-2.0-0 \
    libsdl2-mixer-2.0-0 \
    libpng16-16 \
    libgme0 \
    libcurl4 \
    tmux \
    less \
    nano \
    && apt-get clean

RUN adduser --disabled-password -gecos "" ringracers
USER ringracers

ARG RR_VER="v2.3"
ARG RR_PORT="5029"

ENV RR_PORT=${RR_PORT}
ENV ADVERTISE="Yes"

WORKDIR /home/ringracers/
COPY --chown=ringracers --from=assets /RingRacers/ ./
COPY --chown=ringracers --from=builder /home/ringracers/rr_git/build/ninja-release/bin/ringracers_${RR_VER} ringracers

EXPOSE ${RR_PORT}/udp

COPY --chown=ringracers entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ./entrypoint.sh
HEALTHCHECK --interval=30s --start-period=30s CMD "./entrypoint.sh monitor"