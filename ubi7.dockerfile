FROM registry.access.redhat.com/ubi7/s2i-base

LABEL maintainer="Anaconda, Inc."

ENV CONDA_VERSION=4.9.2
ENV ANACONDA_PROJECT_VERSION=0.10.0

LABEL io.k8s.description="Run Anaconda Project commands" \
      io.k8s.display-name="Anaconda Project 0.10.0" \
      io.openshift.expose-services="8086:http" \
      io.openshift.tags="builder,anaconda-project,conda" 

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/opt/conda/bin:$PATH \
    PIP_NO_CACHE_DIR=1


### AWS Lambda Runtime Emulator
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /opt/aws/
RUN chmod +x /opt/aws/aws-lambda-rie

### Install and configure miniconda
COPY ./etc/condarc /opt/conda/.condarc
RUN yum install -y wget bzip2 \
    && wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py37_4.9.2-Linux-x86_64.sh -O miniconda.sh \
    && bash miniconda.sh -u -b -p /opt/conda \
    && rm -f miniconda.sh \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && conda install anaconda-project=0.10.0 anaconda-client conda-repo-cli conda-token tini --yes \
    && conda clean --all --yes \
    && chmod -R 755 /opt/conda

COPY ./entrypoints/ /
COPY ./s2i/bin/ /usr/libexec/s2i

RUN chown -R 1001:1001 /opt/app-root

USER 1001

##########################################
## Authenticate to your repo with
## conda-token, anaconda-client,
## or conda-repo-cli by calling one of
## these tools here. This will configure
## access to the repo in the base image.

EXPOSE 8086

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/libexec/s2i/usage"]
