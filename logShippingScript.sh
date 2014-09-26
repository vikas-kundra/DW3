#!/bin/bash

. ./serverConfigurationFIle.cfg

##Evaluating File Name For the File Names
date_val=$(date +'%m_%d_%y')
echo "Date Value stored is $date_val"
file_name=$APP_NAME$date_val



##########################################Function To Send Alert Emails##############################################################################
function ErrorEmail()
{
	cd $WORK_DIR
	error_message=$*
	touch alertEmailTemplate
    cat alertEmailTemplate|sed "s/<MESSAGE>/$error_message/g;s/<DATE>/$m2/g;s/<SENDER_SERVER>/$APP_NAME/g;s/<TO>/$EMAIL_DEST/g;s/<DEST_IP>/$DEST_IP/g;">AlertEmail
    sendmail vikas.kundra25@gmail.com  < AlertEmail
}


##########################################Moving Files From Dblogs And Compressing Them##################################################################
function Compress(){

cd $WORK_DIR
if [[ ! -d "$WORK_DIR" ]]; then
	#statements
	mdkir $WORK_DIR
fi
cd $WORK_DIR
#touch ShippingLog
#chmod 777 ShippingLog

cd $DBLOGS_DIR

db_logs_records=$(ls|wc -l)


db_records_values=$(ls -l|awk {print $9})

##Checking If Files Are Present For Processing in DBLOGS Directory
if [[ db_logs_records -ne 0 ]]; then
	#statements

#chmod 777 File*


if [[ ! -d "$SHIPPEDLOG_DIR" ]]; then
	#statements
	mkdir $SHIPPEDLOG_DIR
fi
##Creating gzip of all the files Present in DBLOG Directory
cd ..
tar cvzf $file_name.tar.gz Dblogs
if [[ $? -eq 0 ]]; then
	#statements
	echo "All Files have been moved Successfully"|
	mv $file_name.tar.gz $SHIPPEDLOG_DIR
	rm $DBLOGS_DIR/*


#echo "File Name is $file_name"
cd $SHIPPEDLOG_DIR
touch $file_name.tar.gz_MD5

##Creating MD5 For the gzip
md5sum $file_name.tar.gz>$file_name.tar.gz_MD5
#cat APP1-23-08-12.tar.gz_MD5 >~/temp/Work/ShippingLog
else
	error="Compress Operation was not Successful"
	ErrorEmail $error
	return 1
fi

fi

}
##########################################Splitting Files And Calculating MD5################################################################
function Split()
{


cd $SHIPPEDLOG_DIR
compressed_records_number=$(ls -l|awk '{print $9}'|grep -v MD5|grep .tar|wc -l)

if [[ ! -d "$ARCHIEVE_DIR" ]]; then
	#statements
	mkdir $ARCHIEVE_DIR
fi

##Checking For Gzip Files in ShippedLogs Directory
if [[ $compressed_records_number -ne 0 ]]; then
	#statements

compressed_records_value=$(ls -l|awk '{print $9}'|grep -v MD5|grep .tar)
	#statements
echo "Value of compressed Records is $compressed_records_value"

##Processing Every gzip file present in Folder
for compressed_record in $compressed_records_value
do
cd $ARCHIEVE_DIR
split -b27091709 $SHIPPEDLOG_DIR/$compressed_record  $compressed_record.
last_val=$?
if [[ $last_val -eq 0 ]]; then
	#statements
index=1
echo "Value in Comprssed Record is $compressed_record"
file_val="$compressed_record"
str="lists"
y="$file_name"_$str

touch $y
##Renaming Split Files
for file in $compressed_record.*
do
    
    mv "$file" "$file_val.$index"
 #   md5sum "$j.$i"
    index=`expr $index + 1` 
done

file_collection=$(ls -l|awk '{print $9}'|grep $compressed_record)
	

##Creating MD5 For all the Split Parts
for fil in $file_collection
do
#echo $x
echo $fil>>$y
touch "$fil"_MD5	
md5sum "$fil">"$fil"_MD5
done

cd $SHIPPEDLOG_DIR
rm $compressed_record

else
##Sending Alert Mail in case Split operation is not Performed Successfully
error_messag="Cannot Perform Split For $compressed_record"
AlertEmail $error_messag
fi
done

fi
}

###############################Function To Check For Archieve in Logs Failed###########################################################
function LogFailedCheck() {
	
  if [[ ! -d "$LOG_FAILED_DIR" ]]; then
	#statements
	mkdir $LOG_FAILED_DIR


    else


    cd $LOG_FAILED_DIR
	records=$(ls|wc -l)
	if [[ $records != 0 ]]; then
		#statements
		echo "Inside Function To Transfer Files"
		mv $LOG_FAILED_DIR/* $ARCHIEVE_DIR||ErrorEmail "Unable To Move Files From LogFailed To Archieve Folder"
#		if [[ $? -ne 0 ]]; then
#			ErrorEmail "Unable To Move Files From LogFailed To Archieve Folder"
			#statements
#		fi
	fi
  fi
}
#################################Function For Retrial Logic##################################################################################################
function ReTrial(){

val=1

##Loop For The Number Of Attempts For Retrial
while [[ $val -le $NUMBER_OF_RETRIAL ]]; do
	
	
echo "Value for Retrial Attempts is $val"
#rsync -rauzvq -e "ssh -o ConnectTimeout=2 -o ServerAliveInterval=5" --bwlimit=200  --progress $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
rsync -a -i  -e  "ssh -o ServerAliveInterval=10" --bwlimit=2500  --progress --timeout=5   $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
Last_Rec=$?
echo "Value for exit status is $Last_Rec"
if [[ $Last_Rec -eq 0 ]]; then
	#statements
	echo "Transfer Is SuccessFul..After Retrial"
	return 0

elif [[ $Last_Rec -eq 23 ]]; then
	#statements
	echo "Error in local Directory Path"
	return 1

elif [[ $Last_Rec -eq 11 ]]; then
	echo "Error In Destination Directory Path"
	return 1
		#statements
elif [[ $Last_Rec -eq 255 ]]; then
	#statements
	echo "Remote Connection Is not establishing.."
	sleep 5
#	break

fi
val=$(($val+1))
done

if [[ $val -eq $NUMBER_OF_RETRIAL+1 ]]; then
	#statements
	echo "Transfer Was Not Successful..Even After Retrial!!!"
    return 1
fi

}

######################################################Function For Transfering#########################################################
function Transfer(){
#rsync -a -i  -e ssh --bwlimit=20 --log-file=./Result2	  --timeout=5  /home/ubuntu/temp/Work/Middle/$1  $vikas2@$192.168.0.213:~/temp/Work/Middle

####### Checking If File Has Already been Transferred#############
echo "Inside Transfer for File $1"
echo $1|grep Sent
pipe_v=${PIPESTATUS[1]}


if [[ ! -d "$LOG_SUCCESS_DIR" ]]; then
	#statements
	mkdir $LOG_SUCCESS_DIR
fi

if [[ ! -d "$LOG_FAILED_DIR" ]]; then
	#statements
	mkdir $LOG_FAILED_DIR
fi


if [[ $pipe_v -eq 0 ]]; then
	#statements
	echo "File is Already Present,Don't Need To Resend"
	mv $1 $LOG_SUCCESS_DIR
else

##Transferring File To Remote Server

#rsync -rauzvq -e ssh  --bwlimit=80  --progress  $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
#rsync -a -i  -e  "ssh -o ConnectTimeout=2" --bwlimit=300   --progress   $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
#rsync -a -i  -e ssh --bwlimit=300   --progress --timeout=5  $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
insert_val=0
echo "Exit"|sqlcmd -S 192.168.0.66 -U archit -P password
#conn_value=$(sqlcmd -S 192.168.0.66 -U archit -P password)
conn_value=$?
echo "Connection Value is $conn_value"
if [[ $conn_value -ne 0 ]]; then
	#statements
	insert_val=1
fi
check_val=0 
present_in_db=0   
echo "Select TOP 1 fileName from DW.dbo.log_ship_archieve where fileName='$1' "|sqlcmd -S 192.168.0.66 -U archit -P password|grep -w $1
check_val=${PIPESTATUS[2]}

echo "Value Of Existence of file is $check_val"
if [[ $check_val -eq 0 ]]; then
	#statements
	present_in_db=1
fi


    fileName=$1
	echo "File Name is $fileName"
	parentName=$(echo $1|awk -F '.' '{OFS=FS}{print $1,$2,$3}')
	echo "Parent Name is $parentName"
	MD5=$(md5sum $1)
	echo "MD5 is $MD5"
	Shipped=0
	Integrity=1

if [[ $insert_val -eq 0 && $present_in_db -eq 0 ]]; then
	#statements

echo "insert into DW.dbo.log_ship_archieve(fileName,parentName,MD5,Shipped,Integrity) values('$fileName','$parentName','$MD5','$Shipped','$Integrity')
go"|sqlcmd -S 192.168.0.66 -U archit -P password	
present_in_db=1
fi



rsync -a -i  -e  "ssh -o ServerAliveInterval=10" --bwlimit=2500   --progress --timeout=5   $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
Last_Rec=$?
if [[ $Last_Rec -eq 0 ]]; then
	##Db Insertion Logic

	Shipped=1
	echo "Shipped Value is $Shipped"
	Integrity=1
	echo "Integrity Value is $Integrity	"
	Stat="Done"
	
if [[ $insert_val -eq 0 ]]; then
	#statements
echo "update DW.dbo.log_ship_archieve set Shipped=1,Integrity=1,Status='Done' where fileName='$fileName'  
	go"|sqlcmd -S 192.168.0.66 -U archit -P password
echo "Query Executed Perfectly"
else
echo "insert into  DW.dbo.log_ship_archieve values('$fileName','$parentName','$MD5','$Shipped','$Integrity','Done')  
	go"|sqlcmd -S 192.168.0.66 -U archit -P password

fi
	

    file_name_sent="$1_Sent"
	mv "$1" "$1_Sent"
	echo  "Value for Y is " $file_name_sent
	#mv "$1" "$1"
	echo "Transfer Is SuccessFul..Exiting This Loop"
	mv $file_name_sent $LOG_SUCCESS_DIR
 
else 
 echo "Attempting retrial Logic"
   ReTrial $1
	   last_command_value=$?
   echo "Value in Last Variab is $last_command_value"
   if [[ $last_command_value == 0 ]]; then
    #statements
   
echo "Exit"|sqlcmd -S 192.168.0.66 -U archit -P password
#conn_value=$(sqlcmd -S 192.168.0.66 -U archit -P password)
conn_value_third=$?
echo "Connection Value is $conn_value"
if [[ conn_value_third -eq 0 ]]; then
	#statements

if [[ $insert_val -eq 0 && $present_in_db -ne 0 ]]; then
	#statements
echo "update DW.dbo.log_ship_archieve set Shipped=1,Integrity=1,Status='Done' where fileName='$fileName'  
	go"|sqlcmd -S 192.168.0.66 -U archit -P password
echo "Query Executed Perfectly"
else
	newShipped=1
echo "insert into  DW.dbo.log_ship_archieve values('$fileName','$parentName','$MD5','$newShipped','$Integrity','Done')  
	go"|sqlcmd -S 192.168.0.66 -U archit -P password

fi




 	mv $1 $LOG_SUCCESS_DIR
fi
   else
  

    Shipped=0
    Integrity=0
    Stat="Failed"


echo "Exit"|sqlcmd -S 192.168.0.66 -U archit -P password
#conn_value=$(sqlcmd -S 192.168.0.66 -U archit -P password)
conn_value_second=$?
echo "Connection Value is $conn_value"
if [[ $conn_value_second -eq 0 ]]; then
	#statements
	
  echo "update DW.dbo.log_ship_archieve set Shipped=0,Integrity=1,Status='$Stat' where fileName='$fileName'
go"|sqlcmd -S 192.168.0.66 -U archit -P password
fi
    mv $1 $LOG_FAILED_DIR
   
   fi 
fi

fi


}
#######################################For Transferring Lists Of Split Parts###########################################################
function TransferLists(){

cd $ARCHIEVE_DIR
file_list=$(ls -l|awk '{print $9}'|grep "list")
Transfer $file_list

}



#######################################For Transferring MD5 Files#######################################################################
function TransFerMD(){

cd $ARCHIEVE_DIR
##Searching For all MD5 Files in Archieve Directory
md5_file_collection=$(ls -l|awk '{print $9}'|grep MD5)
#echo "Inside TransferMD"
for md5_file in $md5_file_collection
do
    Transfer $md5_file
done
}    



####################################Function To Transfer Archieves######################################################################
function TransferArchieves(){

cd  $ARCHIEVE_DIR
##Searching for all Files except MD5 in Archieve Directory
file_archieve_collection=$( ls -l|awk '{print $9}'|grep -v MD5|grep -v lists|grep tar.gz)
#echo "Inside TransferMD"
for file_archieve in $file_archieve_collection
do
    Transfer $file_archieve
done

}

####################################Function Which Is Used To Send Email After Transfer####################################################
function SendEmail(){

##List of files Which Have been Transferred
cd $LOG_SUCCESS_DIR
file_success_collection=$(ls -l|awk '{print $9}'|grep Sent)
l=" "
v=0
for x in $file_success_collection
do
	v=`expr $v + 1`
	k=$(echo $x|sed 's/_Sent//')
    l=$l" "$k
#  echo "Value in inner loop of l is $l"
done

#echo "Value in k is $l"
#cat EFile|sed "s/<FILES_SUCCESS>/$l/g"


##List Of Files Which  Have Failed In Transfer
cd $LOG_FAILED_DIR
file_failed_collection=$(ls -l|awk '{print $9}'|grep .tar.gz)
l1=" "
cd $LOG_SUCCESS_DIR
v1=0
#echo "Value inner loop is $m" 
for x in $file_failed_collection
do
	v1=`expr $v1 + 1`
	k=$(echo $x|sed 's/_Sent//')
  l1=$l1" "$k
 # echo "Value in inner loop of l is $l"
done

#echo "Value in k is $l"
cd $WORK_DIR
m2=$(date)	
echo "Date is $m2"

if [[ $v -ne 0 ]]; then


echo "Inside Success Loop"
touch emailFile
cat successTemplate|sed "s/<SUBJECT>/Success Mail/g;s/<FILES_SUCCESS>/$l/g;s/<DATE>/$m2/g;s/<SENDER_SERVER>/$APP_NAME/g;s/<DEST_NAME>/$EMAIL_DEST/g;s/<DEST_IP>/$DEST_IP/g;">emailFile
sendmail vikas.kundra25@gmail.com  < emailFile
fi


if [[ $v1 -ne 0 ]]; then


echo "Inside Failed Loop"
touch emailFailedFile
cat failedTemplate|sed "s/<SUBJECT>/Failed Files/g;s/<FILES_FAILED>/$l1/g;s/<DATE>/$m2/g;s/<SENDER_SERVER>/$APP_NAME/g;s/<DEST_NAME>/$EMAIL_DEST/g;s/<DEST_IP>/$DEST_IP/g;">emailFailedFile
sendmail vikas.kundra25@gmail.com  < emailFailedFile

fi
}

#####################################################Function Which is used To Update DB In Case Of Connection Is Lost To DB################
function UpdateDB(){

##Checking For Files in LogSuccess
cd $LOG_SUCCESS_DIR
file_values=$(ls -l|awk '{print $9}')

for file in $file_values

do 
file_orig=$(echo $file|sed 's/_Sent//')
echo "Select  fileName From DW.dbo.log_ship_archieve where fileName='$file_orig' and Shipped='0' 
 go "|sqlcmd -S 192.168.0.66 -U archit -P password|grep 1
 check_Var=${PIPESTATUS[2]}
 echo "Value of Check varibale is $check_Var"

 if [[ $check_Var -eq 0 ]]; then
 	#statements

# 	echo "File --->$file is Not  Present"
echo "Default Record Is Present "
echo "update DW.dbo.log_ship_archieve set Shipped=1,Integrity=1,Status='Done' where fileName='$file_orig'  
	go"|sqlcmd -S 192.168.0.66 -U archit -P password

fi
done

###Checking in Log Failed For Existence Of Record in DataBase

cd $LOG_FAILED_DIR
file_values=$(ls -l|awk '{print $9}')
for file in $file_values

do 

echo "Select  fileName From DW.dbo.log_ship_archieve where fileName='$file' 
 go "|sqlcmd -S 192.168.0.66 -U archit -P password|grep 1
 check_Var=${PIPESTATUS[2]}
 echo "Value of Check varibale is $check_Var"

 if [[ $check_Var -eq 1 ]]; then

parentName=$(echo $file|awk -F '.' '{OFS=FS}{print $1,$2,$3}')
	echo "Parent Name is $parentName"
	MD5=$(md5sum $file)
	echo "MD5 is $MD5"
	Shipped=0
	Integrity=1

 echo "insert into  DW.dbo.log_ship_archieve values('$file','$parentName','$MD5','$Shipped','$Integrity','Failed')
go"|sqlcmd -S 192.168.0.66 -U archit -P password


fi
done



##Updating Status Column For Files Not Transferred 
echo "Update DW.dbo.log_ship_archieve set Status='Failed' where Shipped='0' and Status='INPROGRESS' 
 go "|sqlcmd -S 192.168.0.66 -U archit -P password


}

######################################Function To Generate MD5 of all Transferred Files#######################################
function GenerateMD5()
{
	cd $WORK_DIR
	str="_MD5"
	y=$file_name$str
	if [[ -f $y ]]; then
		#statements
	rm $y
	fi
	
	echo "Value of FileName Being Created is $y"
	touch $y
	cd $LOG_SUCCESS_DIR
	file_values=$(ls -l|awk '{print $9}'|grep -v lists)

for file in $file_values

do 
echo "Value of filename is $file"

md5sum $file>>$WORK_DIR/$y
done

	
cd $WORK_DIR
rsync -a -i  -e  "ssh -o ServerAliveInterval=10" --bwlimit=2500   --progress --timeout=5   $WORK_DIR/$y	 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
Last_Rec=$?
 
}


######################################Function To Resend Those Files Which Failed Integrity Test##################################
function IntegrityCheck(){


integ_value=$(echo "Select  fileName From DW.dbo.log_ship_archieve where Integrity='0' and Shipped='1'
 go "|sqlcmd -S 192.168.0.66 -U archit -P password)


integ_value=$(echo "$integ_value"|grep -v row|grep -v fileName|grep -v -)
echo "File Values being Retrieved are: $integ_value"
sent="_Sent"

for file in $integ_value
do
	temp_name=$file$sent
new_name=$(echo $temp_name|sed 's/_Sent//')
echo "Now Value is $new_name"
#mv $temp_name $new_name
mv $LOG_SUCCESS_DIR/$temp_name $ARCHIEVE_DIR/$new_name


cd $LOG_SUCCESS_DIR	
done



}


#Order Of Function Calls

Compress
Split

LogFailedCheck
IntegrityCheck

TransferLists
TransferArchieves

UpdateDB
GenerateMD5

#SendEmail


	
		