FROM ubuntu:24.04
LABEL maintainer="Ertan Onur <eronur@metu.edu.tr>"

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

ARG VERSION
ARG INET_VERSION
ARG BUILDARCH
ENV LANG=tr_TR.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

RUN export DEBIAN_FRONTEND=noninteractive &&  \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && add-apt-repository -y universe && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends git wget curl ca-certificates \
        build-essential pkg-config ccache clang lld gdb bison flex perl python3 \
        python3-pip python3-venv python3-dev libxml2-dev zlib1g-dev doxygen \
        graphviz xdg-utils libdw-dev x11-apps xterm  mpi-default-dev libopenscenegraph-dev\
        locales console-setup keyboard-configuration  x11-xkb-utils swig cmake vim x11-xserver-utils && \
    apt-get clean && \
    apt-get install -y --no-install-recommends qt6-base-dev qt6-base-dev-tools qmake6 libqt6svg6 qt6-wayland libwebkit2gtk-4.1-0 \ 
        libxcb-cursor0 \
        xorg-dev libglfw3 libglfw3-dev freeglut3-dev

WORKDIR /root

RUN wget https://github.com/omnetpp/omnetpp/releases/download/omnetpp-$VERSION/omnetpp-$VERSION-linux-$BUILDARCH.tgz \
         --referer=https://omnetpp.org/ -O omnetpp-core.tgz --progress=dot:giga && \
         tar xf omnetpp-core.tgz && rm omnetpp-core.tgz

RUN mv omnetpp-$VERSION omnetpp
WORKDIR /root/omnetpp
ENV PATH=/root/omnetpp/bin:$PATH
RUN python3 -m venv .venv --upgrade-deps --clear --prompt "omnetpp/.venv" && \
    source .venv/bin/activate && \
    python3 -m pip install -r python/requirements.txt && \
    source ./setenv && \
    ./configure WITH_LIBXML=yes WITH_OSG=yes WITH_OSGEARTH=no CXXFLAGS=-std=c++17 && \
    make -j $(nproc)

#INET

WORKDIR /root/omnetpp/samples

RUN wget https://github.com/inet-framework/inet/releases/download/v$INET_VERSION/inet-$INET_VERSION-src.tgz \
         --referer=https://omnetpp.org/ -O inet-src.tgz --progress=dot:mega && \
         tar xf inet-src.tgz && rm inet-src.tgz

WORKDIR /root/omnetpp

RUN source /root/omnetpp/setenv && cd samples/inet4.5 && source setenv && \
    make makefiles && \make makefiles && \
    make -j $(nproc) MODE=release

COPY --chmod=0755 --chown=root:root ./requirements.txt /requirements.txt
RUN  source /root/omnetpp/.venv/bin/activate && \
    pip install -r /requirements.txt && \
    rm /requirements.txt


WORKDIR /root/omnetrl

RUN echo 'xterm*faceSize: 14' >> /root/.Xresources && \
    echo 'xterm*faceName: DejaVuSansMono' >> /root/.Xresources && \
    echo 'xterm*geometry: 80x80' >> /root/.Xresources && \
    echo 'PS1="cengwins:\w\$ "' >> /root/.bashrc && \
    chmod +x /root/.bashrc && \
    touch /root/.hushlogin && \
    echo "source /root/omnetpp/setenv" >> ~/.bashrc && \
    echo "source /root/omnetpp/samples/inet4.5/setenv" >> ~/.bashrc && \
    echo "xrdb -merge /root/.Xresources" >> ~/.bashrc && \
    echo "source /root/omnetpp/.venv/bin/activate" >> ~/.bashrc && \
    echo "export PYTHONPATH=$PYTHONPATH:/root/omnetrl" >> ~/.bashrc && \
    sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG  && \
    echo "keyboard-configuration  keyboard-configuration/layoutcode string tr" | debconf-set-selections && \
    echo "keyboard-configuration  keyboard-configuration/modelcode string pc105" | debconf-set-selections && \
    echo "keyboard-configuration  keyboard-configuration/variantcode string " | debconf-set-selections && \
    dpkg-reconfigure -f noninteractive keyboard-configuration  && \
    echo "setxkbmap tr" >>  ~/.bashrc

RUN apt -y update && apt install -y texlive-full texlive-latex-recommended

CMD ["xterm"]
