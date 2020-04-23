FROM registry.gitlab.com/couchbits/movestore/movestore-groundcontrol/movestore-apps/copilot-shiny:pilot1.0.0-r3.6.3-s1.4.0.2 AS buildstage

# install system dependencies required by this app
RUN apt-get update && apt-get install -qq -y --no-install-recommends \
  libgdal-dev \
  libproj-dev \
  libudunits2-dev

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
# spatial-limit                packrat-multi-stage              aede04d7f1cb        17 minutes ago      2.39GB
# <none>                       <none>                           0df415987e52        41 minutes ago      2.62GB

#FROM rocker/r-base:3.6.3
#WORKDIR /root/app
#COPY --from=buildstage /root/app .
#COPY --from=buildstage /usr/lib/R/etc/Rprofile.site /usr/lib/R/etc/

ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/root/app/app.jar"]
