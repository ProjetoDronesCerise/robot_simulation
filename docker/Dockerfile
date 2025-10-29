FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DISPLAY=:99
ENV TERM=xterm
ENV TZ=UTC

# SITL UDP PORTS
EXPOSE 14556/udp
EXPOSE 14557/udp

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    build-essential \
    git \
    sudo \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY modules/ /workspace/
RUN rm -rf /workspace/PX4-Autopilot

RUN git clone -b v1.16.0 https://github.com/PX4/PX4-Autopilot.git --recursive

RUN bash /workspace/PX4-Autopilot/Tools/setup/ubuntu.sh

# remove o harmonic instalado pela px4
RUN apt-get remove -y gz-harmonic && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*


RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
RUN apt-get update
RUN apt-get install -y gz-ionic

# o make nao aceita se o diretorio nao for considerado seguro
# copiado do dockerfile original da px4
RUN git config --global --add safe.directory '/workspace/PX4-Autopilot'
RUN useradd --shell /bin/bash -u 1001 -c "" -m user && usermod -a -G dialout user

RUN cd /workspace/PX4-Autopilot && make px4_sitl

CMD ["/bin/bash"]
