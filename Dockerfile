FROM registry.gitlab.com/couchbits/movestore/movestore-groundcontrol/movestore-apps/copilot-shiny:pilot1.0.0-r3.6.3-s1.4.0.2 AS buildstage

WORKDIR /root/app

RUN Rscript -e 'remotes::install_version("units", "0.6-6")'
RUN Rscript -e 'remotes::install_version("sp")'
RUN Rscript -e 'remotes::install_version("sf")'
RUN Rscript -e 'remotes::install_version("leaflet", "2.0.3")'
RUN Rscript -e 'remotes::install_version("leaflet.extras")'
RUN Rscript -e 'remotes::install_version("pals")'
RUN Rscript -e 'remotes::install_version("leafem")'
RUN Rscript -e 'remotes::install_version("leafpop")'
RUN Rscript -e 'remotes::install_version("mapview")'
RUN Rscript -e 'remotes::install_version("rgeos")'
RUN Rscript -e 'remotes::install_version("move")'
RUN Rscript -e 'remotes::install_version("lubridate")'
RUN Rscript -e 'remotes::install_version("rgdal")'
RUN Rscript -e 'packrat::snapshot()'

# copy the app as last as possible
# therefore following builds can use the docker cache of the R dependency installations
COPY ShinyModule.R .

# start again from the vanilla r-base image and copy only
# the needed binaries from the buildstage.
# this will reduce the resulting image size dramatically
# spatial-limit    packrat-multi-stage              0cd0f8b22301        2 minutes ago       1.62GB
# <none>           <none>                           fbe3f6d9458e        3 minutes ago       2.62GB

FROM rocker/r-base:3.6.3
WORKDIR /root/app
COPY --from=buildstage /root/app .
COPY --from=buildstage /usr/lib/R/etc/Rprofile.site /usr/lib/R/etc/

# TODO: can we copy the libraries from the base-image? do we even need them during build?
RUN apt-get update && apt-get install -qq -y --no-install-recommends \
  libgdal-dev \
  libproj-dev \
  libudunits2-dev \
# Install JRE for pilot
  default-jre && \
# Fix certificate issues
  apt-get install ca-certificates-java && \
  apt-get clean && \
  update-ca-certificates -f;

ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/root/app/app.jar"]
