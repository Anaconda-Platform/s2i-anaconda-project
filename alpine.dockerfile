FROM frolvlad/alpine-glibc:alpine-3.12_glibc-2.32

LABEL maintainer="Anaconda, Inc."

ENV CONDA_VERSION=4.9.2
ENV ANACONDA_PROJECT_VERSION=0.10.0

LABEL io.k8s.description="Run Anaconda Project commands" \
      io.k8s.display-name="Anaconda Project 0.10.0" \
      io.openshift.expose-services="8086:http" \
      io.openshift.tags="builder,anaconda-project,conda" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PATH=/opt/conda/bin:$PATH 
ENV PYTHONDONTWRITEBYTECODE=1
ENV HOME=/opt/app-root/src

COPY ./etc/condarc /opt/conda/.condarc

### Install and configure miniconda
RUN apk add --no-cache --virtual wget tar bash \
    && wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py37_4.9.2-Linux-x86_64.sh -O miniconda.sh \
    && sh miniconda.sh -u -b -p /opt/conda \
    && rm -f miniconda.sh \
    && conda install anaconda-project=0.10.0 anaconda-client conda-repo-cli conda-token tini --yes \
    && conda clean --all --yes \
    && chmod -R 755 /opt/conda 

COPY ./s2i/bin/ /usr/libexec/s2i

RUN mkdir -p /opt/app-root && \
    chown -R 1001:1001 /opt/app-root

USER 1001

##########################################
## Authenticate to your repo with
## conda-token, anaconda-client,
## or conda-repo-cli by calling one of
## these tools here. This will configure
## access to the repo in the base image.

EXPOSE 8086

WORKDIR $HOME

ENTRYPOINT ["tini", "-g", "--"]

CMD ["/usr/libexec/s2i/usage"]
