#/bin/bash
#=============================================================================
# Lo script è all'interno di un container
#
# ogni giorno esegue uno script R che interroga il DBmeteo
# produce i grafici relativi allo zero termico
# e li carica su Minio
#
# 2019/02/07 MR
# 2020/09/22 MR inserita chiamata a unico file R per entrambi i grafici
#               e inserita pulizia cartella di Minio
# 2021/04/24 MR tolto caricamento su Minio, introdotta copia si ghost e grafici altre variabili
#=============================================================================

ZEROT_R='zeroT.R'
WIND_R='wind_Z.R'
RELHUM_R='relhum_Z.R'
RAD_R='radG_Z.R'
#PRES_R='press_Z.R'
WINDD_R='dirv_Z.R'
PREC_R='prec_Z.R'
#NIVO_R='nivo_Z.R'

DATA_DOMANI=$(date -d "tomorrow" +%Y-%m-%d)
METEOGRAMMA_ALPI="meteogramma_"$DATA_DOMANI"_alpi.png"
METEOGRAMMA_PIANURA="meteogramma_"$DATA_DOMANI"_pianura.png"
#
while [ 1 ]
do

########################
   Rscript $RAD_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $RAD_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento e su ghost
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/rad/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/rad_log/
   fi
   ## aggiungo a meteogramma e rimuovo
   #### ATTENZIONE, PRIMO GRAFICO USA IMMAGINE BIANCA CATTURA.GIF !!!
   convert *_alpi.png Cattura.gif -append temporanea_alpi.gif
   convert *_pianura.png Cattura.gif -append temporanea_pianura.gif
   rm -f *.png


########################
   Rscript $RELHUM_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $RELHUM_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento e su ghost
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/relhum/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/relhum_log/
   fi
   ## aggiungo a meteogramma e rimuovo
   convert *_alpi.png temporanea_alpi.gif -append temporanea_alpi.gif
   convert *_pianura.png temporanea_pianura.gif -append temporanea_pianura.gif
   rm -f *.png

########################
   Rscript $WINDD_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $WINDD_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento e su ghost
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/dirv/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/dirv_log/
   fi
   ## aggiungo a meteogramma e rimuovo
   convert *_alpi.png temporanea_alpi.gif -append temporanea_alpi.gif
   convert *_pianura.png temporanea_pianura.gif -append temporanea_pianura.gif
   rm -f *.png

########################
   Rscript $WIND_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $WIND_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento e su ghost
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/velv/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/velv_log/
   fi
   ## aggiungo a meteogramma e rimuovo
   convert *_alpi.png temporanea_alpi.gif -append temporanea_alpi.gif
   convert *_pianura.png temporanea_pianura.gif -append temporanea_pianura.gif
   rm -f *.png

########################
   Rscript $PREC_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $PREC_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento e su ghost
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/prec/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/prec_log/
   fi
   ## aggiungo a meteogramma e rimuovo
   convert *_alpi.png temporanea_alpi.gif -append temporanea_alpi.gif
   convert *_pianura.png temporanea_pianura.gif -append temporanea_pianura.gif
   rm -f *.png

########################
   Rscript $ZEROT_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $ZEROT_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento e su ghost
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/zeroT/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/zeroT_log/
   fi
   ## aggiungo a meteogramma e rimuovo
   convert *_alpi.png temporanea_alpi.gif -append temporanea_alpi.gif
   convert *_pianura.png temporanea_pianura.gif -append temporanea_pianura.gif
   rm -f *.png

######################################

  # assegno data a temporanea e copio tra i meteogrammi
       mv temporanea_alpi.gif $METEOGRAMMA_ALPI
       mv temporanea_pianura.gif $METEOGRAMMA_PIANURA
       sshpass -p $pwd_ghost scp *_alpi.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/meteogrammi/
       sshpass -p $pwd_ghost scp *_pianura.png meteo@10.10.0.14:/var/www/html/prodottimeteo/SINERGICO/zero_T/immagini/meteogrammi_log/
       rm -f *.png

   sleep 10800 # 3 ore
#fi
done
exit 0

