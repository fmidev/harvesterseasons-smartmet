FROM docker.io/centos:7
#FROM centos:7.6.1810
LABEL maintainer "Mikko Strahlendorff mikko.strahlendorffo@fmi.fi>"
LABEL license    "MIT License Copyright (c) 2020 FMI Open Development"

ENV USER_NAME="smartmet" \
    NOTO_FONTS="NotoSans-unhinted NotoSerif-unhinted NotoMono-hinted" \
        GOOGLE_FONTS="Open%20Sans Roboto Lato Ubuntu"

# install smartmet-server including grid-engine grid-admin grid-gui and tools
RUN yum -y install https://download.fmi.fi/smartmet-open/rhel/7/x86_64/smartmet-open-release-latest-7.fmi.noarch.rpm && \
    yum -y update && \
    yum -y install epel-release && \
    yum-config-manager --setopt="epel.exclude=librsvg2*" --save && \
    yum-config-manager --setopt="base.exclude=librsvg2*" --save && \
    yum-config-manager --disable epel-source && \ 
    yum -y install \
    smartmet-plugin-backend \
    smartmet-plugin-admin \
    smartmet-plugin-download \
    smartmet-plugin-timeseries \
    smartmet-plugin-wms \
    smartmet-engine-grid \
    smartmet-plugin-grid-admin \
    smartmet-plugin-grid-gui \
    smartmet-tools-grid \
    smartmet-qdtools \
    unzip && \
    yum -y reinstall --setopt=override_install_langs='' --setopt=tsflags='' glibc-common eccodes && \
    yum clean all 

# Install Google Noto fonts
RUN mkdir -p /usr/share/fonts/truetype/noto && \
     for FONT in ${NOTO_FONTS}; \
     do \
         curl -s -S -o ${FONT}.zip https://noto-website-2.storage.googleapis.com/pkgs/${FONT}.zip && \
         unzip -o ${FONT}.zip -d /usr/share/fonts/truetype/noto && \
         rm -f ${FONT}.zip ; \
     done

# Install Google Fonts
RUN \
    for FONT in $GOOGLE_FONTS; \
    do \
        mkdir -p /usr/share/fonts/truetype/${FONT} && \
        curl -s -S -o ${FONT}.zip "https://fonts.google.com/download?family=${FONT}" && \
        unzip -o ${FONT}.zip -d /usr/share/fonts/truetype/${FONT} && \
        rm -f ${FONT}.zip ; \
    done
					    
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:8080/admin?what=qengine || exit 1

# Expose SmartMet Servers default port
EXPOSE 8080

#COPY smartmetconf /etc/smartmet
#COPY wms /smartmet/share/wms
#COPY docker-entrypoint.sh /

# wms.conf defines imagecache. timeseriescache's use is yet to be found.
# MS 6.3.20: from new Rauhala dockerhub code
RUN mkdir -p /var/smartmet/timeseriescache /var/smartmet/imagecache /var/smartmet/querydata/validpoints && \
    chgrp -R 0 /var/smartmet/timeseriescache /var/smartmet/imagecache /var/smartmet/querydata/validpoints && \
    chmod -R g=u /var/smartmet/timeseriescache /var/smartmet/imagecache /var/smartmet/querydata/validpoints /etc/passwd /var/log

# M.K. 09.01.2020: adopted it to WEkEO paths 
RUN mkdir -p /srv/data
RUN useradd -r -u 1001 smartmet
# M.K. 09.01.2020: /srv/grid-data adopted to WEkEO setting
#                  other paths are not created in step before TODO check!
RUN chown -R smartmet /srv/data /var/log/smartmet /var/smartmet/timeseriescache /var/smartmet/imagecache

# Smartmet Servers configs should be separate from /etc's settings that come from RPM-packages
# These locations are required to be defined in several different setting files under the config-direcotry
# M.K. 09.01.2020: do I have to change something here? Dockerfile is aborting here.
COPY scripts /home/smartmet/scripts 
RUN chown -R smartmet /home/smartmet/scripts

# Dont use root to run commands in container
USER smartmet

# Uncomment to include files in Docker image. 
# Comment and add in compose-file for development
#COPY --chown=smartmet config /home/smartmet/config 

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["smartmetd"]
