######################################################################################
#  codice per estrarre i dati di temperatura di alcune stazioni scelte
#  e produrre i grafici con evidenza dello zero termico
#  
#  EB & MR 18/12/2018
######################################################################################

#--------------------------------------------------------------------------------
inizio <- Sys.Date()-1
fine <- Sys.Date() 
#dir<-"//10.10.49.211/meteo/Progetti/AlternanzaScuolaLavoro/2019/"
dir<-"/home/meteo/sviluppo/zero_T/"
aree <- c("Prealpi_Varesine", "Lario","Prealpi_Centrali", "Val_Chiavenna","Valtellina", "Alta_Valtellina","Prealpi_Orientali","Pianura_Orientale","Pianura_Occidentale","Appennino")
colore <- c("black","red","purple","green","blue","violet","cyan","brown","blue")
#------------------------------------------------------------------------------

library(DBI)
library(RMySQL)

# funzione per gestire eventuali errori
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:")
  quit(status=1)
}
options(show.error.messages=TRUE,error=neverstop)

# riconoscimento date
Tini<-as.POSIXct(strptime(inizio,format="%Y-%m-%d"),"UTC")
Tfin<-as.POSIXct(strptime(fine,format="%Y-%m-%d"),"UTC")

################ impostazione dei grafici
nome_pdf <- paste(dir,"/","aree.pdf",sep="")
pdf(nome_pdf,width=8,height=40,bg = "white",paper="special")
nf<-layout(matrix(c(1,2,3,4,5,6,7,8,9,10),10,1, byrow = TRUE))
par(mar = c(2,5,2,20))


# connessione al DB
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password="guardone", dbname="METEO", host="10.10.0.6"))
if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DB \n")
  print( "chiusura connessione malriuscita ed uscita dal programma \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}


# ciclo sulle aree
area <- 1
while (area<length(aree)+1){
  
#lettura del file
 lettura<-read.csv (paste(dir,aree[area],'.csv', sep="" ),sep=";")
 IDsensore<-lettura$IdSensore
 Nome<-paste(lettura$Comune,lettura$Attributo,sep=" ")
 Quota<-lettura$Quota
 
 #ciclo sui sensori: richiesta dati e calcolo massimi e minimi per grafico 
 tmin <- 100
 tmax <- -100
 n<-1
 while(n<length(IDsensore)+1){
   # richiesta dati escludendo sensori in lista nera
   query= paste('select Data_e_ora, Misura from M_Osservazioni_TR where IDsensore =',IDsensore[n],' and Data_e_ora>"',Tini,'" and Data_e_ora<"',Tfin,'"  and IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL);',sep="")
   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   temperatura<-result_query$Misura
   tmin <- min(tmin,temperatura,na.rm=T)
   tmax <- max(tmax,temperatura, na.rm=T)
   n <- n + 1
 }
  
 # impostazione grafico
   plot(Tini,0,ylim=c(tmin,tmax), xlim=c(Tini,Tfin),type="n", main=aree[area], xaxt='n',  yaxt='n',xlab='', ylab='Temp (C)')
   par(xpd=F) # impedisco di uscire dall'area del grafico
   abline(h=0, lwd=2, col="red")
   #asse y
   sequenza <- seq(tmin, tmax, by=(tmax-tmin)/5)
   ticchi   <- round(seq(tmin, tmax, by=(tmax-tmin)/5), digits=0)
   axis(2                    ,
        sequenza             ,
        lwd      = 1         ,
        las      = 1         ,
        labels   = ticchi    ,
        cex.axis = 1.3       ,   # dimensioni LABELS
        mgp      = c(0.4,1,0))
   
   #asse x
   sequenza    <- seq(Tini, Tfin, by = "6 hours")
   giornaliere <- format(seq(Tini, Tfin, by = "6 hours"),"%a %H")
   axis(1                      ,
        c(Tini:Tfin)           ,
        lwd     =  1           ,   # spessore asse
        col     = 'black'      ,   # colore ASSE
        labels  =  giornaliere ,   # SCRITTE
        at      =  sequenza    )   # posizione SCRITTE
   
   
    #linee verticali
    par(xpd=F)  # impedisco di uscire dall'area del grafico
    abline(v=seq(Tini, Tfin, by="12 hours"   ),         
          lty = 1,                                     
          col = 'gray')
    abline(v=seq(Tini, Tfin, by="6 hours"),           
          lty = 2,                                   
          col='gray')
   
 #ciclo sui sensori: richiesta dati e grafico 
 n<-1
   while(n<length(IDsensore)+1){

   # richiesta dati
   query= paste('select Data_e_ora, Misura from M_Osservazioni_TR where IDsensore =',IDsensore[n],' and Data_e_ora>"',Tini,'" and Data_e_ora<"',Tfin,'";',sep="")
   result_query<-try(dbGetQuery(conn,query), silent=TRUE)
   data<-as.POSIXct(strptime(result_query$Data_e_ora,format="%Y-%m-%d %H:%M:%S"),"UTC")
   temperatura<-result_query$Misura
  
   if(length(temperatura)>0){         # se ci sono i dati eseguo il grafico
     lines(data,temperatura,col=colore[n])
     #legenda
     par(xpd=T) # permetto di uscire dall'area del grafico
     legend(Tfin , tmax + 1 - n,
              legend = paste(Nome[n],"-",Quota[n],"m",sep=""),
              horiz=F,               # orizzontale
              bty="n",               # senza box
              cex=1,                 # dimensione scritta
              text.col=colore[n])    # colore scritta
   }else{                            #se non ci sono dati non eseguo il grafico ma inserisco il nome in legenda in grigio
     legend(Tfin , tmax + 1 - n,
            legend = paste(Nome[n],"-",Quota[n],"m",sep=""),
            horiz=F,               # orizzontale
            bty="n",               # senza box
            cex=1,                 # dimensione scritta
            text.col="gray")       # colore scritta
   }
   n <- n + 1
   }
 
 area <- area + 1
}

###############################################

# disconnessione dal DB 
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)



