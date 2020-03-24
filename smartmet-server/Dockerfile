FROM docker.io/centos:7
#FROM centos:7.6.1810
LABEL maintainer "Mikko Strahlendorff mikko.strahlendorffo@fmi.fi>"
LABEL license    "MIT License Copyright (c) 2020 FMI Open Development"

ENV USER_NAME="smartmet" \
    NOTO_FONTS="NotoSans-unhinted NotoSerif-unhinted NotoMono-hinted" \
        GOOGLE_FONTS="Open%20Sans Roboto Lato Ubuntu"

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm \
        https://download.fmi.fi/smartmet-open/rhel/7/x86_64/smartmet-open-release-17.9.28-1.el7.fmi.noarch.rpm && \
	sed -i 's:\]k:\]:g' /etc/yum.repos.d/pgdg-redhat-all.repo &&   yum-config-manager --disable "pgdg*" && \
                yum-config-manager --enable "pgdg95"

# Install version 9.5  before postgis to prevent 9.2 from being installed
# The version 9.5 seems to be a dependency for smartmet-tools-grid
RUN yum -y update \
    yum -y install postgresql95

# This should install from epel
# Postgis requires some libraries that are installed with postgresql
# The postgres95 should be installed before postgis to prevent wrong versions
# being installed as a dependency
RUN yum -y install postgis
# gribwms plugin required librsvg2
RUN yum -y install librsvg2-2.40.6-3.el7.x86_64

# The order of packages installed seems to affect dependencies from working 
RUN yum -y install smartmet-plugin-backend \
  smartmet-plugin-admin \
   smartmet-plugin-download \
    smartmet-plugin-gribtimeseries \
     smartmet-plugin-grid-admin \
      smartmet-plugin-grid-gui \
       smartmet-plugin-gribwfs \
        smartmet-plugin-gribwms \
	 unzip 
#    yum -y install smartmet-plugin-timeseries && \
#    yum -y install smartmet-plugin-wms && \


# For installing filesys2smartmet which is used to load grib-files to redis
RUN yum -y install smartmet-tools-grid smartmet-qdtools && yum clean all 

# M.K. 09.01.2020: until here, installation seems to work Install Google Noto fonts
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
# M.K. 09.01.2020: this is not working; should be checked
#RUN mkdir -p /var/log/smartmet /var/smartmet/timeseriescache /var/smartmet/imagecache
# MS 6.3.20: from new Rauhala dockerhub code
RUN mkdir -p /var/smartmet/timeseriescache /var/smartmet/imagecache /var/smartmet/querydata/validpoints && \
    chgrp -R 0 /var/smartmet/timeseriescache /var/smartmet/imagecache /var/smartmet/querydata/validpoints && \
    chmod -R g=u /var/smartmet/timeseriescache /var/smartmet/imagecache /var/smartmet/querydata/validpoints /etc/passwd /var/log

# M.K. 09.01.2020: adopted it to WEkEO paths 
RUN mkdir -p /srv/data
RUN useradd smartmet
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
