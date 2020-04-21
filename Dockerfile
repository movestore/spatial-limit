FROM registry.gitlab.com/couchbits/movestore/movestore-groundcontrol/movestore-apps/pilot-r:pilot1.0.0-r3.6.3-shiny1.4.0.2

COPY ShinyModule.R /root/app/shiny/ShinyModule.R

WORKDIR /root/app/shiny

RUN jetpack init

RUN jetpack add units@0.6-6
RUN jetpack add sp
RUN jetpack add sf
RUN jetpack add leaflet@2.0.3
RUN jetpack add leaflet.extras
RUN jetpack add pals
RUN jetpack add leafem
RUN jetpack add leafpop
RUN jetpack add mapview
RUN jetpack add rgeos

RUN Rscript -e 'packrat::init()'

RUN cat DESCRIPTION
RUN cat packrat.lock
