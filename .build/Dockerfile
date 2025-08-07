FROM nvidia/cuda:12.3.2-cudnn9-devel-ubuntu22.04
LABEL authors="nirajan.thakuri@fusemachines.com, bhupin@fusemachines.com"

RUN chmod 1777 /tmp && chmod 1777 /var/tmp

# install apt-utils in header to fix warnings in docker-stacks
RUN apt-get update && \
    apt-get -y install apt-utils

ARG ROOT_CONTAINER=ubuntu:22.04

ARG NB_USER="studio"
ARG NB_UID="1000"
ARG NB_GID="100"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root 

# Install all OS dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    bzip2 \
    ca-certificates \
    locales \
    netbase \
    sudo \
    tini \
    wget \
    fonts-liberation \
    pandoc \
    run-one \
    curl \
    git \
    nano-tiny \
    tzdata \
    gettext-base \
    unzip \
    vim-tiny \
    openssh-client \
    less \
    texlive-latex-base \
    xclip \
    build-essential \
    ffmpeg && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # Set locale
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Define the Python version as a build argument
ARG PYTHON_VERSION=3.10

# Install Python and pip
RUN apt-get update && \
    apt-get install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Make the installed version the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

RUN update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10

# RUN pip install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | \
    env UV_INSTALL_DIR=/usr/local/bin sh

# Configure environment
ENV SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    HOME="/home/${NB_USER}/work"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

COPY run-hooks.sh start.sh /usr/local/bin/

# Create dirs for startup hooks
RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create "${NB_USER}" user (`studio` by default) with UID="${NB_UID}" (`1000` by default) and in the 'users' group
# and make sure these dirs are writable by the `users` group.
# Restrict switch to other user
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --no-user-group "${NB_USER}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "/home/${NB_USER}"

# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"

WORKDIR "${HOME}"

RUN uv pip install --system --upgrade aim ipykernel && \
    fix-permissions "/home/${NB_USER}"

# Install nvtop to monitor the gpu tasks
RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake libncurses5-dev libncursesw5-dev git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install system dependencies required by JupyterLab and extensions
RUN apt-get update && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Jupyter ecosystem with uv (from PyPI)
RUN uv pip install --system \
    jupyterlab \
    notebook \
    nbclassic \
    jupyterhub && \
    jupyter server --generate-config && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "/home/${NB_USER}"

RUN mkdir /aim
RUN fix-permissions /aim

RUN mkdir /temp_file

WORKDIR /tmp

# Clear /tmp directory
RUN rm -rf /tmp/*

WORKDIR "${HOME}"

# Copy local files as late as possible to avoid cache busting
COPY start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

RUN fix-permissions /etc/jupyter/

# HEALTHCHECK
HEALTHCHECK --interval=3s --timeout=1s --start-period=3s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

# Install useful packages and Graphviz
RUN apt-get update \
 && apt-get -y install --no-install-recommends htop iputils-ping graphviz libgraphviz-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# upgrade jupyter-server for compatibility
RUN set -ex \
 && buildDeps=' \
    distributed==2024.11.2 \
    jupyter-server==2.14.2 \
 ' \
 && uv pip install --system $buildDeps \
 && fix-permissions "/home/${NB_USER}"

RUN set -ex \
 && buildDeps=' \
    jupyterlab_code_formatter \
    black \
    isort \
    # jupyterlab_execution_time \
    jupyterlab-git \
    jupytext \
    jupyterlab-lsp \
    nbdime \
    kiteconnect \
    # jupyterlab-nbgather \
    jupyterlab-latex \
    # jupyterlab-spellchecker \
    # jupyterlab-toc \
    # jupyterlab-google-drive \
    # s3browser \
    # systemmonitor \
    ' \
    && uv pip install --system $buildDeps \
    && fix-permissions "/home/${NB_USER}"

RUN npm install -g pyright

COPY uv_setup.sh /temp_file/
RUN chmod -R +x /temp_file

USER ${NB_UID}

# Set env-var JUPYTER_TOKEN as static token
ARG JUPYTER_TOKEN
ENV JUPYTER_TOKEN=$JUPYTER_TOKEN
COPY jupyter_server_config_token_addendum.py /etc/jupyter/
RUN cat /etc/jupyter/jupyter_server_config_token_addendum.py >> /etc/jupyter/jupyter_server_config.py

# Configure container entrypoint
ENTRYPOINT ["tini", "-g", "--", "start.sh"]

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

# Configure container startup
CMD ["start-notebook.py"]

USER root

COPY user-settings/ /home/${NB_USER}/.jupyter/lab/user-settings
RUN fix-permissions "/home/${NB_USER}"

USER ${NB_UID}