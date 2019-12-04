FROM arpasmr/r-base
RUN R -e "install.packages('lattice', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('graphics', repos = 'http://cran.us.r-project.org')"
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
CMD ["./grafici_zeroT.sh"]
