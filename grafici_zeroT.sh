#!/bin/bash
#=============================================================================
# Lo script è all'interno di un container
#
# ogni giorno esegue uno script R che interroga il DBmeteo
# produce i grafici relativi allo zero termico
# e li carica su Minio
#
# 2019/02/07 MR
#=============================================================================

ZEROT_R='zeroTlevelplot.R'


putS3() {
  path=$1
  file=$2
  aws_path=$3
  bucket=$4
  date=$(date -R)
  acl="x-amz-acl:public-read"
  content_type='application/x-compressed-tar'
  string="PUT\n\n$content_type\n$date\n$acl\n/$bucket/$aws_path$file"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  curl -X PUT -T "$path/$file" \
    --progress-bar \
    -H "Host: $S3HOST" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${S3KEY}:$signature" \
    "http://$S3HOST/$bucket/$aws_path$file"
}

#
while [ 1 ]
do
# procedi sono se sono le 15
if [ $(date "+%H") == "15" ];
then
   Rscript $ZEROT_R

   # verifico se è andato a buon fine
   STATO=$?
   echo "STATO USCITA DA "$ $ZEROT_R" ====> "$STATO

   if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
   then
       exit 1
   else # caricamento su MINIO
       putS3 . *.png zeroT/ rete-monitoraggio

       # controllo sul caricamento su MINIO
       if [ $? -ne 0 ]
       then
         echo "problema caricamento su MINIO"
         exit 1
       fi
   fi

   rm -f *.png
   #sleep 86400 # 1 giorno
   sleep 600
fi
done
exit 0
