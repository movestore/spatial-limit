FROM registry.gitlab.com/couchbits/movestore/movestore-groundcontrol/movestore-apps/pilot-base

RUN apt-get update && \
    apt-get install -y libudunits2-dev && \
    apt-get clean;

RUN R -e "install.packages(c('units', 'sp', 'sf', 'leaflet', 'leaflet.extras', 'pals', 'leafem', 'leafpop', 'mapview', 'rgeos'), repos='https://cloud.r-project.org/')"

COPY ShinyModule.R /root/app/shiny/ShinyModule.R
