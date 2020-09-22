FROM rocker/r-base
MAINTAINER Ilicic
RUN apt-get update && apt-get install -y \
        sudo \
        pandoc \
        pandoc-citeproc \
        libcurl4-gnutls-dev \
        libcairo2-dev \
        libxt-dev \
        libssl-dev \
        libssh2-1-dev \
        libmariadbclient-dev\
        default-jdk\
        zip \
        libmpfr-dev

RUN apt-get install -y \
            texlive \
            texlive-latex-extra

RUN apt-get install -y \
libv8-dev

RUN R -e "install.packages(c('shiny', 'rmarkdown'), repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages(c('shiny','tidyverse','tibble','dplyr','qcc','stringr'), repos = 'http://cran.rstudio.com/')"


RUN mkdir /root/app
COPY . /root/app
EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/app')"]
