#########################################
## Terraformers Docker Setup ##
#########################################

FROM osrf/ros:jazzy-desktop
ENV ROS_DISTRO=jazzy

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

# Basic setup
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends --allow-unauthenticated \
    autoconf \
    automake \
    bash-completion \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    g++ \
    git \
    iproute2 \
    iputils-ping \
    libxext-dev \
    libx11-dev \
    make \
    mc \
    mesa-utils \
    nano \
    vim \
    tree \
    pkg-config \
    software-properties-common \
    sudo \
    tmux \
    tzdata \
    xclip \
    x11proto-gl-dev \
    ros-jazzy-rmw-cyclonedds-cpp \
    python3-pip \
    screen \
    figlet \
    toilet \
    libxcb-cursor0 \
    && rm -rf /var/lib/apt/lists/*

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# install VS Code server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# install python extension
RUN code-server --install-extension ms-python.python

RUN pip install ipython roboticstoolbox-python==1.1.1 python-fcl==0.7.0.8 transforms3d==0.4.2 opencv-contrib-python==4.9.0.80 opencv-python==4.9.0.80 numpy==1.26.4 --break-system-packages && \
    export PATH=/home/terry/.local/bin:$PATH

# Set datetime and timezone correctly
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' | tee -a /etc/timezone

ENV DEBIAN_FRONTEND=dialog

# install ros packages
RUN apt-get update && apt-get install -y \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-gz-ros2-control \
    ros-jazzy-foxglove-bridge \
    ros-jazzy-joint-state-publisher-gui \
    ros-jazzy-moveit \
    ros-jazzy-moveit-common \
    ros-jazzy-moveit-ros-planning \
    ros-jazzy-moveit-ros-move-group \
    ros-jazzy-moveit-ros-control-interface \
    ros-jazzy-ur-description \
    ros-jazzy-ur-moveit-config \
    ros-jazzy-ur-robot-driver \
    ros-jazzy-ur-calibration \
    ros-jazzy-realsense2-camera \
    ros-jazzy-realsense2-camera-msgs \
    ros-jazzy-realsense2-description \
    ros-jazzy-aruco-markers-msgs* \
    ros-jazzy-cv-bridge \
    ros-jazzy-realsense2* \
    ros-jazzy-aruco-opencv* \
    ros-jazzy-usb-cam \
    ros-jazzy-rqt-image-view

RUN apt-get update \
    && apt-get install -y ros-jazzy-gz-*

# Add OSRF Gazebo repository and key, then install Gazebo development library
# needed for gz completions
RUN apt-get update && apt-get install -y --no-install-recommends gnupg lsb-release ca-certificates curl && \
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list && \
    apt-get update && apt-get install -y libgz-tools2-dev && \
    rm -rf /var/lib/apt/lists/*

# defaults
ARG userid=1002
ARG groupid=1002

RUN groupadd -g "${groupid}" terry \
 && useradd -m -u "${userid}" -g "${groupid}" -G sudo,video terry

RUN usermod -aG 1000 terry

# Create or reuse the user safely
RUN set -eux; \
    if getent passwd "${userid}" > /dev/null 2>&1; then \
        existing_user="$(getent passwd "${userid}" | cut -d: -f1)"; \
        echo "Reusing existing UID ${userid} (user: ${existing_user}) as 'terry'"; \
        usermod -l terry -d /home/terry -m "${existing_user}"; \
    else \
        echo "Creating new user 'terry' with UID ${userid} and GID ${groupid}"; \
        groupadd -g "${groupid}" terry || true; \
        useradd -ms /bin/bash -u "${userid}" -g "${groupid}" -G sudo,video terry; \
    fi && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


USER terry
ENV HOME=/home/terry
WORKDIR /home/terry

# ROS_LOCALHOST_ONLY is deprecated
# LIBGL_ALWAYS_SOFTWARE=1 causes performance issues with Gazebo rendering
ENV USER=terry \
    LANG=en_US.UTF-8 \
    ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST \
    HOME=/home/terry \
    LIBGL_ALWAYS_SOFTWARE=0 \
    TZ=America/New_York

RUN sudo mkdir -p -m 0700 /run/user/${userid} && \
    sudo chown ${userid}:${groupid} /run/user/${userid}

# ros workspace
RUN source /opt/ros/jazzy/setup.bash \
    && mkdir -p ~/terraformers-ws/src
# ros workspace
RUN source /opt/ros/jazzy/setup.bash

RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc && \
    echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc && \
    # segmentation fault workaround
    echo 'if [ -n "$DISPLAY" ]; then export QT_QPA_PLATFORM=xcb; fi' >> ~/.bashrc && \
    # autocompletion for Gazebo CLI
    echo "source /usr/share/bash-completion/completions/gz" >> ~/.bashrc && \
    # echo "export ROS_LOCALHOST_ONLY=1" >> ~/.bashrc && \
    echo "export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST" >> ~/.bashrc && \
    echo "export GZ_VERSION=harmonic" >> ~/.bashrc && \
    echo "alias clc=clear" >> ~/.bashrc && \
    # clear terminal when starting
    echo "clear" >> ~/.bashrc 

# Setup tmux config
ENTRYPOINT ["/bin/bash", "-i"]