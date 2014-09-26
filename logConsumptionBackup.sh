#!/bin/bash

. ./serverConfigurationFIle.cfg

file_to_resend=""

function ErrorEmail()
{
  cd $WORK_DIR
  error_message=$*
  touch alertEmailTemplate
    cat alertEmailTemplate|sed "s/<MESSAGE>/$error_message/g;s/<DATE>/$m2/g;s/<SENDER_SERVER>/$APP_NAME/g;s/<TO>/$EMAIL_DEST/g;s/<DEST_IP>/$DEST_IP/g;">AlertEmail
    sendmail vikas.kundra25@gmail.com  < AlertEmail
}


function MoveLists(){
	cd ~/temp/VM
  files_list_unique=$(ls -l|awk '{print $9}'|grep -v "MD5"|awk 'BEGIN { FS="." } { print $1 }'|awk -F, '{a[$1];}END{for (i in a)print i;}')
	
	#echo "Value of Different Compressed Arvhieves are"
	#echo $files_list_unique
	
    
    files_recieved_unique=$(ls -l|awk '{print $9}'|grep "lists")
    
    for file_each in $files_recieved_unique
    do
   file_list_name=$(echo $file_each|awk -F '_' 'BEGIN {OFS=FS} {print$1,$2,$3}')
   echo "Value of directory is $file_list_name"
   cd ~/temp
   if [[ ! -d "$file_list_name" ]]; then
   	#statements
   mkdir ~/temp/$file_list_name
   fi
   cd ~/temp/VM
   mv $file_each ~/temp/$file_list_name
    done
}

function CalculateMD5()
{
	cd ~/temp/VM
	files=$(ls -l|awk '{print $9}'|grep -v "MD5"|awk 'BEGIN { FS="." } { print $1 }'|awk -F, '{a[$1];}END{for (i in a)print i;}')
	echo "Value of Different Compressed Arvhieves are"
	echo $files
	for file in $files
	do
    files_recieved=$(ls -l|awk '{print $9}'|grep -v "MD5"|grep -v "lists")
    echo "Recieved files are $files_recieved"
    
  ##Loop For Calculating MD5 of compressed Recieved
    for fr in $files_recieved
    do
  # echo "Initial Value is $fr"
   val=$fr
   dirVal=$(echo $fr|awk 'BEGIN { FS="." } { print $1 }')
   echo "Value of Directory is $dirVal"
  cd ~/temp
  ##Checking For Existence of Directory
  if [[ ! -d "$dirVal" ]]; then
  	#statements
  	mkdir ~/temp/$dirVal
  fi
   cd ~/temp/VM
   str="_MD5"
   file_val=$val$str
    echo "Generated File is $file_val"

#echo "Opening MD5 File " 

#cat $file$str










#   if [[ ! -f $file_val ]]; then
   	#statements
 #  	echo "File Does not Exist"
  #  file_to_resend=$file_to_resend$file_val
    
  
str1="_Sent"


 #   else

val1=$(md5sum $fr|awk '{print $1}')
#echo "value of md5 Generated is $val1"
echo "Value Obtained from Generate MD5 on Remote Server is $val1"
val2=$(cat $file$str|grep -w $fr$str1|awk '{print $1}')
echo "Value obtained from MD5 File Stored  is $val2"

if [[ "$val1" == "$val2" ]]; then
	#statements
	echo "MD5  Matches"
mv $fr ~/temp/$dirVal
#rm $file_val
else
	

  echo "MD5 does not Matches"
echo "update  DW.dbo.log_ship_archieve values set Integrity ='0' where fileName='$fr'
go"|sqlcmd -S 192.168.0.66 -U archit -P password    

fi
#fi
done
done
#echo "File_s to be Resend $file_to_resend"
}


function CheckParts() {

cd ~/temp
file_directories=$(ls -l|grep "APP"|awk '{print $9}')
echo "Value of File Directory is $file_directories"

 for file_directory in $file_directories
 do
cd ~/temp/$file_directory
#ls -l|grep "APP"|awk '{print $9}'>Check

if [[ ! -d "Dblogs" ]]; then
  #statements


list_str="lists"
tar_str=".tar.gz"
list_temp_name="$file_directory"_"$list_str"
echo "Value of temp Name is $list_temp_name"
check_val=$(ls -l|grep "APP"|awk '{print $9}'|grep -v "lists")
echo "Value inside check_val is $check_val"
m1=$(cat $list_temp_name)

echo "Value in M is $m1"
 


##Condition To check Whether MD5 Matches or not
if [[ "$check_val" == "$m1" ]]; then
	#statements
echo "All Parts have been Recieved"
touch $file_directory
#cat $file_directory_*>$file_directory

#n=$(echo $file_directory_*|grep -v "lists")
#echo $n
##Obtaining File Names In Sorted Order
m2=$(ls -1v $file_directory*|grep -v "lists")  
echo "Value in m2 is $m2  "

for file_value_check in $m2
do

	cat $file_value_check>>$file_directory
	done 
echo "Name Of File is $file_directory"

tar -xvf $file_directory
cd /home/ubuntu/temp/$file_directory/Dblogs
db_files=$(ls -l|awk '{print $9}')
echo "Dblogs Files are $db_files"
for db_file in $db_files
do

table_name=$(echo $db_file|awk -F _ '{OFS="_"}{print $1,$2}')
echo "Table Name is $table_name"
echo "File name is $db_file"
sed -i 's/GMT//g' /home/ubuntu/temp/$file_directory/Dblogs/$db_file
str_Store="_store"

##Creating Temporary Table In which Files Need To Be Dumped
if [[ $table_name == "raw_requests" ]]; then
  #statements

  echo "Inside Raw_Request Temp statements"
  temp_table=$table_name$str_Store
  echo "Temp_Table Value is $temp_table"
  echo "Create Table DW.dbo.$temp_table  (time               DATETIME,
  ad_id              INT,
  width              INT,
  height             INT,
  profile_key        VARCHAR(64),
  partner_channel_id INT,
  response_code      INT);"|sqlcmd -S 192.168.0.66 -U archit -P password

else if [[ $table_name == "raw_impressions" ]]; then
  #statements
  echo "Inside raw_impressions statements"
temp_table=$table_name$str_Store
echo "Temp_Table Value is $temp_table"
echo "Create Table DW.dbo.$temp_table  (time               DATETIME,
  ad_id              INT,
  width              INT,
  height             INT,
  profile_key        VARCHAR(64),
  partner_channel_id INT,
  response_code      INT);"|sqlcmd -S 192.168.0.66 -U archit -P password
else

  echo "Inside raw_clicks statements"
  temp_table=$table_name$str_Store
  echo "Temp_Table Value is $temp_table"
echo "Create Table DW.dbo.$temp_table  (time               DATETIME,
  ad_id              INT,
  width              INT,
  height             INT,
  profile_key        VARCHAR(64),
  partner_channel_id INT,
  response_code      INT);"|sqlcmd -S 192.168.0.66 -U archit -P password  
fi

fi
#sed -i 's/GMT//g' /home/ubuntu/Downloads/SQLConnect/Dblogs/raw_requests_version_1_app1_db.log.rotated.2013051011.log  
  

  echo "Present Date is " $(date)
  bcp DW.dbo.$temp_table  in  "/home/ubuntu/temp/$file_directory/Dblogs/$db_file" -f "/home/ubuntu/Downloads/SQLConnect/$table_name.fmt"  -S 192.168.0.66 -U archit -P password 
  Last_cmd=$?

  echo "Value of Last Command Status is $Last_cmd"

if [[ $Last_cmd -eq 0 ]]; then
  #statements
echo "Transfer is SuccessFull"  
echo "Data Has Been Tranferred!!!!!!"
#echo "Update DW.dbo.log_ship_archieve Set Completed='1' where parentName='$file_directory$tar_str'"|sqlcmd -S 192.168.0.66 -U archit -P password
echo "Starting Process to Transfer File"
echo "Insert Into DW.dbo.$table_name Select * from DW.dbo.$temp_table
go
Drop Table DW.dbo.$temp_table"|sqlcmd -S 192.168.0.66 -U archit -P password


else

echo "Current Date is " $(date)
echo "Transfer was not SuccessFull"
error="Plz Remove $temp_table From DataBase"
ErrorEmail $error
fi
done
else
echo "Files Does not Match"
fi
fi
done
}

MoveLists
CalculateMD5
 CheckParts 