#########################################
## Terraformers Docker Setup - JETSON  ##
#########################################

FROM dustynv/ros:jazzy-desktop-r36.4.0-cu128-24.04
ENV ROS_DISTRO=jazzy

# 1. Essential Environment Setup
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
SHELL ["/bin/bash", "-c"]

# 2. Consolidated APT Install (Prevents OOM and Exit 100)
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf automake bash-completion build-essential ca-certificates \
    cmake curl g++ git iproute2 iputils-ping libxext-dev libx11-dev \
    make mc mesa-utils nano vim tree pkg-config software-properties-common \
    sudo tmux tzdata xclip x11proto-gl-dev python3-pip screen figlet \
    toilet libxcb-cursor0 \
    # ROS Jazzy Packages
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
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
    ros-jazzy-rqt-image-view \
    && rm -rf /var/lib/apt/lists/*

# 3. Development Tools
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 4. Python Environment (Breaking system packages is required for Jazzy/Ubuntu 24.04)
# 1. Install system-level build dependencies first
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfcl-dev libccd-dev g++ git \
    && rm -rf /var/lib/apt/lists/*

# 2. Install numpy and other simple wheels first
RUN pip install --no-cache-dir --break-system-packages \
    ipython transforms3d==0.4.2 numpy==1.26.4 \
    opencv-contrib-python==4.9.0.80 opencv-python==4.9.0.80

# 3. Handle problematic libraries
# If python-fcl fails, we install it via a git source or an compatible version
# RUN pip install --no-cache-dir --break-system-packages \
#     git+https://github.com/BerkeleyAutomation/python-fcl.git@master \
#     roboticstoolbox-python==1.1.1

# 5. User Management (Ensures Terrence can write to files)
ARG userid=1000
ARG groupid=1000

RUN if getent passwd ${userid}; then \
        user_old=$(getent passwd ${userid} | cut -d: -f1); \
        usermod -l terrence $user_old; \
        groupmod -n terrence $(getent group ${groupid} | cut -d: -f1); \
        usermod -d /home/terrence -m terrence; \
    else \
        groupadd -g ${groupid} terry && \
        useradd -m -u ${userid} -g ${groupid} terry; \
    fi && \
    echo "terrence ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER terrence
WORKDIR /home/terrence/terraformers-ws

# 6. ROS Workspace & Bashrc Setup
# RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
#     echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc && \
#     echo "export GZ_VERSION=harmonic" >> ~/.bashrc


#RUN chmod +x ./start_ros.bash

RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
    echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc && \
    echo "export GZ_VERSION=harmonic" >> ~/.bashrc