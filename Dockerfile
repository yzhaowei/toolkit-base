FROM rocker/geospatial:3.6.2

ENV NB_USER rstudio
ENV NB_UID 1000
ENV VENV_DIR /srv/venv
ENV SHELL /bin/bash

# Set ENV for all programs...
ENV PATH ${VENV_DIR}/bin:$PATH
# And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

# The `rsession` binary that is called by nbrsessionproxy to start R doesn't seem to start
# without this being explicitly set
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

ENV HOME /home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

USER ${NB_USER}

RUN python3 -m venv ${VENV_DIR} && \
    # Explicitly install a new enough version of pip
    pip3 install pip==9.0.1 && \
    pip3 install --no-cache-dir \
         jupyterlab==1.0.4 jupyter-rsession-proxy==1.0b6 && \
    wget https://nodejs.org/dist/v10.16.1/node-v10.16.1-linux-x64.tar.xz && \
    xz -d node-v10.16.1-linux-x64.tar.xz && \
    tar xvf node-v10.16.1-linux-x64.tar && \
    export PATH=/home/rstudio/node-v10.16.1-linux-x64/bin:$PATH && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install jupyterlab-drawio && \
    rm -rf node-v10.16.1-linux-x64* && \
    rm -rf /tmp/*

RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')" && \
    rm -rf /tmp/*

EXPOSE 8888
CMD ["jupyter", "lab","--ip=0.0.0.0", "--no-browser"]


## If extending this image, remember to switch back to USER root to apt-get
