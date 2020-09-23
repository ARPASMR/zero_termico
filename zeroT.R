#########################################################################
#  produzione di un levelplot coi dati di temperatura                   #
#  misurati e sovrapposto lo zero termico da radiosondaggio             #
#                                                                       #
#  EB & MR 18/12/2018                                                   #
#  MR 04/12/2019 dockerizzato                                           #
#  MR 14/09/2020 estrazione pluv e neve da stessa query delle temp      #
#                per migliore gestione dati da unico df                 #
#########################################################################

#-----------------------------------------------------------------------
inizio <- Sys.Date()-4
fine <- Sys.Date()
#----------------------------------------------------------------------

library(DBI)
library(RMySQL)
library(lattice)
library(graphics)

# funzione per gestire eventuali errori
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:")
  quit(status=1)
}
options(show.error.messages=TRUE,error=neverstop)

# riconoscimento date
Tini<-as.POSIXct(strptime(inizio,format="%Y-%m-%d"),"UTC")
Tfin<-as.POSIXct(strptime(fine,format="%Y-%m-%d"),"UTC")
time<-as.POSIXct(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 hour"))


# connessione al DB
drv<-dbDriver("MySQL")
#################
conn<-try(dbConnect(drv, user=as.character(Sys.getenv("MYSQL_USR")), password=as.character(Sys.getenv("MYSQL_PWD")), dbname=as.character(Sys.getenv("MYSQL_DBNAME")), host=as.character(Sys.getenv("MYSQL_HOST"))))
#################
if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DB \n")
  print( "chiusura connessione malriuscita ed uscita dal programma \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

########## leggo altezza zero T da radiosondaggio di Linate
    queryLinate=paste("select data, zmin, zmax from RADIO_elaborazioni where data >='",inizio,"' and data <='",fine, "';",sep="")
   result_queryLinate<-try(dbGetQuery(conn,queryLinate), silent=TRUE)
   dataLinate<-as.POSIXct(strptime(result_queryLinate$data,format="%Y-%m-%d %H:%M"),"UTC")
   zmin <- result_queryLinate$zmin
   zmax <- result_queryLinate$zmax

########## LETTURA DELLE MISURE

 condizioni <- paste('DataInizio is not NULL and IDrete in (1,4) and Storico="NO" and sn.IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL) and Flag_manuale in ("M","G") and Flag_manuale_DBunico not in (100,101,102) and Data_e_ora>"',inizio,'" and Data_e_ora<="',fine,'"',sep='')

 select_grandezze1 <- 'select st.IDstazione, st.Quota, g.Misura as Grandezza, g.Data_e_ora FROM A_Stazioni as st, A_Sensori as sn'
 select_grandezze2 <- paste('as g WHERE st.IDstazione=sn.IDstazione and sn.IDsensore=g.IDsensore and ',condizioni)

 query=paste('select temp.Quota, temp.IDstazione, temp.Grandezza as Temperatura, pluv.Grandezza as Precipitazione, niv.Grandezza as Neve, temp.Data_e_ora from ( ',select_grandezze1,', M_Termometri ',select_grandezze2,') temp LEFT JOIN (',select_grandezze1,', M_Pluviometri ', select_grandezze2, ') pluv ON pluv.IDstazione=temp.IDstazione AND pluv.Data_e_ora=temp.Data_e_ora LEFT JOIN (',select_grandezze1,', M_Nivometri ',select_grandezze2,') niv ON temp.IDstazione=niv.IDstazione AND temp.Data_e_ora=niv.Data_e_ora order by temp.IDstazione, temp.Data_e_ora;', sep='')

   result_query <- try(dbGetQuery(conn,query), silent=TRUE)

   precipitazioni <- result_query$Precipitazione
   temperatura <- result_query$Temperatura
   neve <- diff(result_query$Neve)
   data <- as.POSIXct(strptime(result_query$Data_e_ora,format="%Y-%m-%d %H:%M"),"UTC")
   quota <- result_query$Quota
  # precipitazioni[!time %in% data]<-NA

trovaValori = function(a, b){
    i <- which(data == a & quota == b)
    return (temperatura[i[1]])
}
trovaValoriPluvio = function(a, b){
    i <- which(data == a & quota == b)
    return (precipitazioni[i[1]])
}
trovaValoriNeve = function(a, b){
    i <- which(data == a & quota == b)
    return (neve[i[1]])
}

# Plot

x<-unique(data)
y<-unique(quota)
  gdr<-expand.grid(xvar=x, yvar=y)
  gdr$zvar<- mapply("trovaValori", gdr$xvar, gdr$yvar)
  prec<- mapply("trovaValoriPluvio", gdr$xvar, gdr$yvar)
  nev<- mapply("trovaValoriNeve", gdr$xvar, gdr$yvar)

### GRAFICO LINEARE PER FOCUS ALPI

png(paste("zeroT_",fine,".png",sep=""), width = 1500, height = 1000)

myPanel_lin <- function(x=xvar, y=yvar, z=zvar, ..., subscripts=subscripts) {
                panel.levelplot(x=x, y=y, z=z, ..., subscripts=subscripts)
                panel.abline(v = as.POSIXct(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 day")) , col="black")  # linee verticali
                panel.lines(dataLinate,zmax, col="black",lty=1,lwd=2)                             # zeroT da radiosondaggio
                panel.lines(dataLinate,zmin, col="black",ltw=2,lwd=2)                             # zeroT da radiosondaggio
                na<-is.na(z[subscripts])                                                                       # trattino su mancanti
                panel.text(x = x[subscripts[na]], y = y[subscripts[na]], labels = "-",cex=1.5)
                pp<-which(prec > 1)                                                                              # pallino sui precipitazioni
                panel.text(x = x[pp], y = y[pp], labels = "o")
                nn<-which(nev > 5)                                                                              # crocetta sui neve
                panel.text(x = x[nn], y = y[nn], labels = "X",cex=2)
                panel.text(x = x[1], y = y, labels = "#")                                                       # indicatore della quota dei rilevemnti
               }

grafico_lineare <- levelplot (zvar ~ xvar * yvar, data = gdr,
                   panel=myPanel_lin,
                   scales=list(y=list(cex=1 , at=c(300,600,900,1200,1800,2100,2400,2700,3000) ),x=list(at=c(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 day"))), format=("%d-%b %a")),
                   at= unique(c(seq(-20, -1, length=30),c(seq(-1, 1, length=11)),  c(seq(1, 20, length=30)))),
                   main="TEMPERATURE e PRECIPITAZIONI Lombardia da Rete ARPA",
                   col.regions = colorRampPalette(c('dark blue','blue','white','red','yellow')),
                   xlab='Data',ylab='Quota (m)')

print(grafico_lineare)
dev.off()


### GRAFICO SU SCALA LOGARITMICA PER FOCUS PIANURA

png(paste("zeroT_",fine,"_pianura.png",sep=""), width = 1500, height = 1000)

myPanel_log <- function(x=xvar, y=yvar, z=zvar, ..., subscripts=subscripts) {
                panel.levelplot(x=x, y=y, z=z, ..., subscripts=subscripts)
                panel.abline(v = as.POSIXct(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 day")) , col="black")  # linee verticali
                panel.lines(dataLinate,log(zmax,base=10), col="black",lty=1,lwd=2)                             # zeroT da radiosondaggio
                panel.lines(dataLinate,log(zmin,base=10), col="black",ltw=2,lwd=2)                             # zeroT da radiosondaggio
                na<-is.na(z[subscripts])                                                                       # trattino su mancanti
                panel.text(x = x[subscripts[na]], y = y[subscripts[na]], labels = "-",cex=1.5)
                pp<-which(prec > 1)                                                                              # pallino sui precipitazioni
                panel.text(x = x[pp], y = y[pp], labels = "o")
                nn<-which(nev > 5)                                                                              # crocetta sui neve
                panel.text(x = x[nn], y = y[nn], labels = "X",cex=2)
                panel.text(x = x[1], y = y, labels = "-")                                                       # indicatore della quota dei rilevemnti
               }


        grafico_logaritmico <- levelplot (zvar ~ xvar * yvar, data = gdr,
         panel=myPanel_log,
         scales=list(y=list(log=TRUE,cex=1 , at=c(10,50,100,200,300,400,500,600,800,1000,1200,1400,1600,1800,2000,2500) ),x=list(at=c(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 day"))), format=("%d-%b %a")),
         at= unique(c(seq(-20, -1, length=30),c(seq(-1, 1, length=11)),  c(seq(1, 20, length=30)))),
         main="TEMPERATURE e PRECIPITAZIONI Lombardia da Rete ARPA - focus Pianura",
         col.regions = colorRampPalette(c('dark blue','blue','white','red','yellow')),
         xlab='Data',ylab='log(Quota) (m)')

print(grafico_logaritmico)
dev.off()


# disconnessione dal DB
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)
