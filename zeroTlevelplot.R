######################################################################################
#  produzione di un levelplot coi dati di temperatura
#  misurati e sovrapposto lo zero termico da radiosondaggio
#
#  EB & MR 18/12/2018
#  MR 04/12/2019 dockerizzato
######################################################################################

#--------------------------------------------------------------------------------
inizio <- Sys.Date()-11
fine <- Sys.Date()+1
#------------------------------------------------------------------------------

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


################ impostazione dei grafici
nome_png <- paste("zeroT_",fine,"_pianura.png",sep="")
#nome_png<-"zeroT.png"
png(nome_png, width = 1500, height = 1000)

# connessione al DB
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user=as.character(Sys.getenv("MYSQL_USR")), password=as.character(Sys.getenv("MYSQL_PWD")), dbname=as.character(Sys.getenv("MYSQL_DBNAME")), host=as.character(Sys.getenv("MYSQL_HOST"))))
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

########## LETTURA DELLE TEMPERATURE
 temperatura_tot<-vector()
   query='select IDsensore, Quota from A_Sensori,A_Stazioni where A_Sensori.IDstazione=A_Stazioni.IDstazione and DataInizio is not NULL and IDrete in (1,2,4) and NOMEtipologia="T" and Storico="No" and IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL) order by Quota;'
   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   IDsens <- result_query$IDsensore
   Quota <- result_query$Quota

 n<-1
 while(n<length(IDsens)+1){
   query= paste('select Data_e_ora, Misura from M_Termometri where Flag_manuale in ("M","G") and IDsensore=',IDsens[n],' and Data_e_ora>"',Tini,'" and Data_e_ora<="',Tfin,'" ;',sep="")

   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   temperatura <- result_query$Misura
   data<-as.POSIXct(strptime(result_query$Data_e_ora,format="%Y-%m-%d %H:%M"),"UTC")
   # assegno NA alle temperature mancanti
   temperatura[!time %in% data]<-NA
   temperatura_tot <- c(temperatura_tot,temperatura)
   n <- n + 1
 }

########## LETTURA DELLE PRECIPITAZIONI 
  precipitazioni_tot<-vector()
   query='select IDsensore, Quota from A_Sensori,A_Stazioni where A_Sensori.IDstazione=A_Stazioni.IDstazione and DataInizio is not NULL and IDrete in (1,2,4) and NOMEtipologia="PP" and Storico="No" and IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL) order by Quota;'
   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   IDsens <- result_query$IDsensore
   Quota_PP <- result_query$Quota

 #ciclo sui sensori: richiesta dati
 n<-1
 while(n<length(IDsens)+1){
   query= paste('select Data_e_ora, Misura from M_Pluviometri where Flag_manuale in ("M","G") and IDsensore=',IDsens[n],' and Data_e_ora>"',Tini,'" and Data_e_ora<="',Tfin,'" ;',sep="")

   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   precipitazioni <- result_query$Misura
   data<-as.POSIXct(strptime(result_query$Data_e_ora,format="%Y-%m-%d %H:%M"),"UTC")
   # assegno NA alle precipitazioni mancanti
   precipitazioni[!time %in% data]<-NA
   precipitazioni_tot <- c(precipitazioni_tot,precipitazioni)
   n <- n + 1
 }


# Plot
  gdr<-expand.grid(xvar=time,yvar=Quota)
  gdr$zvar <- temperatura_tot

myPanel <- function(x=xvar, y=yvar, z=zvar, ..., subscripts=subscripts) {
                panel.levelplot(x=x, y=y, z=z, ..., subscripts=subscripts)
#               panel.abline(h = Quota_N, col="black")
                panel.abline(v = as.POSIXct(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 day")) , col="black")  # linee verticali
                panel.lines(dataLinate,log(zmax,base=10), col="black",lty=1,lwd=2)                             # zeroT da radiosondaggio
                panel.lines(dataLinate,log(zmin,base=10), col="black",ltw=2,lwd=2)                             # zeroT da radiosondaggio
                na<-is.na(z[subscripts])                                                                       # trattino su mancanti
                panel.text(x = x[subscripts[na]], y = y[subscripts[na]], labels = "-",cex=1.5)
                pp<-which(precipitazioni_tot>1)                                                                # pallino sui precipitazioni
                panel.text(x = x[pp], y = y[pp], labels = "o")
               }

        p<-levelplot (zvar ~ xvar * yvar, data = gdr,
         panel=myPanel,
         scales=list(y=list(log=TRUE,cex=1 , at=c(10,50,100,200,300,400,500,600,800,1000,1200,1400,1600,1800,2000,2500) ),x=list(at=c(seq(as.POSIXct(Tini),as.POSIXct(Tfin),by="1 day"))), format=("%d-%b %a")),
         at= unique(c(seq(-20, -1, length=30),c(seq(-1, 1, length=11)),  c(seq(1, 20, length=30)))),
         main="TEMPERATURE e PRECIPITAZIONI Lombardia da Rete ARPA - focus Pianura",
         col.regions = colorRampPalette(c('dark blue','blue','white','red','yellow')),
         xlab='Data',ylab='log(Quota) (m)')
print(p)


# disconnessione dal DB
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)

