######################################################################################
#  produzione di un levelplot coi dati di temperatura
#  misurati e sovrapposto lo zero termico da radiosondaggio
#
#  EB & MR 18/12/2018
#  MR 04/12/2019 dockerizzato
######################################################################################

#--------------------------------------------------------------------------------
inizio <- Sys.Date()-15
fine <- Sys.Date()
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
#nome_png <- paste("zeroT_",inizio,".png",sep="")
nome_png<-"zeroT.png"
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

   temperatura_tot<-vector()
    query='select IDsensore, Quota from A_Sensori,A_Stazioni where A_Sensori.IDstazione=A_Stazioni.IDstazione and DataInizio is not NULL and IDrete in (1,2,4) and NOMEtipologia="T" and Storico="No" and IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL) order by Quota;'
   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   IDsens <- result_query$IDsensore
   Quota <- result_query$Quota

 #ciclo sui sensori: richiesta dati
 n<-1
 while(n<length(IDsens)+1){
   query= paste('select Data_e_ora, Misura from M_Termometri where IDsensore=',IDsens[n],' and Data_e_ora>"',Tini,'" and Data_e_ora<="',Tfin,'" ;',sep="")

   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   temperatura <- result_query$Misura
   data<-as.POSIXct(strptime(result_query$Data_e_ora,format="%Y-%m-%d %H:%M"),"UTC")
   # assegno NA alle temperature mancanti
   temperatura[!time %in% data]<-NA
   temperatura_tot <- c(temperatura_tot,temperatura)
   n <- n + 1
 }

  gdr<-expand.grid(xvar=time,yvar=Quota)
  gdr$zvar <- temperatura_tot

# Plot
myPanel <- function(x=xvar, y=yvar, z=zvar, ..., subscripts=subscripts) {
                panel.levelplot(x=x, y=y, z=z, ..., subscripts=subscripts)
 #              panel.abline(h = Quota, col="black")
                panel.lines(dataLinate,zmax, col="black",lty=1,pch=16,cex=3)
                panel.lines(dataLinate,zmin, col="black",ltw=2,pch=16,cex=3)
                na<-is.na(z[subscripts])
                panel.text(x = x[subscripts[na]],
                y = y[subscripts[na]],
             #   labels = round(z[subscripts[na]], 1))
                labels = "X")
                }

        p<-levelplot (zvar ~ xvar * yvar, data = gdr,
         panel=myPanel,
         at= unique(c(seq(-25, -1, length=11),c(seq(-1, 1, length=11)),  c(seq(1, 25, length=11)))),
         col.regions = colorRampPalette(c('blue','white','red')),
         xlab='Data',ylab='Quota (m)')
print(p)


# disconnessione dal DB
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)

