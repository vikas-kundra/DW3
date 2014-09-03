file_to_resend=""


function MoveLists(){
	cd ~/temp/VM
    #files_list_unique=$(ls -l|awk '{print $9}'|grep -v "MD5"|awk 'BEGIN { FS="." } { print $1 }'|awk -F, '{a[$1];}END{for (i in a)print i;}')
	
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
   if [[ ! -f $file_val ]]; then
   	#statements
   	echo "File Does not Exist"
    file_to_resend=$file_to_resend$file_val
    
    else
##If file Exists
val1=$(md5sum $fr)
#echo "value of md5 Generated is $val1"
val2=$(cat $file_val)
if [[ "$val1" == "$val2" ]]; then
	#statements
	echo "MD5  Matches"
mv $fr ~/temp/$dirVal
rm $file_val
else
	echo "MD5 does not Matches"
fi





   

fi




done
    


done
echo "File_s to be Resend $file_to_resend"
}


function CheckParts() {
cd ~/temp
file_directories=$(ls -l|grep "APP"|awk '{print $9}')
echo "Value of File Directory is $file_directories"
 for file_directory in $file_directories
 do
cd ~/temp/$file_directory
#ls -l|grep "APP"|awk '{print $9}'>Check
list_str="lists"
list_temp_name="$file_directory"_"$list_str"
echo "Value of temp Name is $list_temp_name"
check_val=$(ls -l|grep "APP"|awk '{print $9}'|grep -v "lists")
echo "Value inside check_val is $check_val"
m1=$(cat $list_temp_name)

echo "Value in M is $m1"
 
if [[ "$check_val" == "$m1" ]]; then
	#statements
echo "All Parts have been Recieved"
touch $file_directory
#cat $file_directory_*>$file_directory

#n=$(echo $file_directory_*|grep -v "lists")
#echo $n
for file_value_check in $m1
do

	cat $file_value_check>>$file_directory
	done

tar -xvf $file_directory
else
echo "Files Does not Match"
	
fi
done

}

MoveLists
CalculateMD5
CheckParts