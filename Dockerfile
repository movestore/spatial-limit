FROM registry.gitlab.com/couchbits/movestore/movestore-groundcontrol/movestore-apps/copilot-shiny:pilot1.0.0-r3.6.3-s1.4.0.2 AS buildstage

WORKDIR /root/app
RUN ls -al
COPY ShinyModule.R ./shiny/
COPY app-dependencies.R .

RUN Rscript -e 'remotes::install_version("units", "0.6-6")' &&\
    Rscript -e 'remotes::install_version("sp")' &&\
    Rscript -e 'remotes::install_version("sf")' &&\
    Rscript -e 'remotes::install_version("leaflet", "2.0.3")' &&\
    Rscript -e 'remotes::install_version("leaflet.extras")' &&\
    Rscript -e 'remotes::install_version("pals")' &&\
    Rscript -e 'remotes::install_version("leafem")' &&\
    Rscript -e 'remotes::install_version("leafpop")' &&\
    Rscript -e 'remotes::install_version("mapview")' &&\
    Rscript -e 'remotes::install_version("rgeos")' &&\
    Rscript -e 'packrat::snapshot()' &&\
RUN ls -al

# start again from the vanilla r-base image and copy only
# the needed binaries from the buildstage.
# this will reduce the resulting image size dramatically
FROM rocker/r-base:3.6.3
#RUN mkdir -p /root/app/shiny
WORKDIR /root/app
COPY --from=buildstage /root/app .
