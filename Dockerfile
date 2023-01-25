FROM debian:11-slim
# modalita' non interattiva
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
# cambio i timeout
RUN echo 'Acquire::http::Timeout "240";' >> /etc/apt/apt.conf.d/180Timeout
# installo gli aggiornamenti ed i pacchetti necessari (courtesy of https://github.com/occ-data/containers/blob/master/grads/Dockerfile et al.)
# tolti libc-dev zlib1g gcc gfortran g++ udunits-bin
RUN apt-get --fix-missing update
RUN apt-get -y install curl git smbclient locales dnsutils openssh-client procps util-linux build-essential ncftp rsync  
RUN apt-get -y install nfs-common openssl libjpeg-dev libpng-dev 
RUN apt-get -y install libreadline-dev r-base r-base-dev
RUN apt-get install -y libmariadb-dev
RUN apt-get install -y libpq-dev
RUN R -e "install.packages('RMySQL', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('lubridate', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('curl', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('foreign', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('lattice', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('graphics', repos = 'http://cran.us.r-project.org')"
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
RUN apt-get install -y sshpass
RUN apt-get install -y imagemagick
RUN apt-get install -y vim
CMD ["./grafici_zeroT.sh"]
