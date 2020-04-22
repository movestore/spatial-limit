FROM registry.gitlab.com/couchbits/movestore/movestore-groundcontrol/movestore-apps/copilot-shiny:pilot1.0.0-r3.6.3-s1.4.0.2 AS buildstage

WORKDIR /root/app
COPY ShinyModule.R ./shiny/

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
RUN Rscript -e 'packrat::snapshot()'

# start again from the vanilla r-base image and copy only
# the needed binaries from the buildstage.
# this will reduce the resulting image size dramatically
FROM rocker/r-base:3.6.3
#RUN mkdir -p /root/app/shiny
WORKDIR /root/app
COPY --from=buildstage /root/app .
