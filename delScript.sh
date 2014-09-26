cd ~/temp 
##Fetching Those FileNames which have been Successfully Transferred
comp_values=$(echo "Select DISTINCT parentName from DW.dbo.log_ship_archieve where Completed='1'"|sqlcmd -S 192.168.0.66 -U archit -P password)

comp_values=$(echo "$comp_values"|grep -v row|grep -v parentName|grep -v -|grep -v lists)

echo "Value Recived are $comp_values"

for comp_value in $comp_values
do 
dir_name=$(echo $comp_value|awk -F '.' '{print $1}')
echo "Directory Name is:$dir_name"
rm -rf $dir_name
done



