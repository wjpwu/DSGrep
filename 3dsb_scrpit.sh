#list all file with .dsx
find ./jobs -print | grep .dsx > alldsxjobs 

#list all pass jobs RejectNumber = 1 
find ./jobs -print|xargs grep -A1 RejectNumber | grep "\"1\"" > resultpass

#list all jobs contaions RejectNumber setting
find ./jobs -print|xargs grep -A1 RejectNumber | grep "Value" | awk '!a[$0]++' > resultall

#list all jobs name
sed "s/:         Value \"0\"//" resultall > tmp1
sed "s/:         Value \"1\"//" tmp1 | awk '!a[$0]++' > alljos
rm tmp1

#list all pass jobs name
sed "s/:         Value \"1\"//" resultpass | awk '!a[$0]++' > passjobs
rm resultall
rm resultpass

#compare and list all unpass jobs name
grep -F -v -f passjobs alljos > unpassjobs

#get reject condition setting and writemode setting
find ./jobs -print|xargs grep -E "<WriteMode modified='1' type='int'>|<WriteMode type='int'>" | awk -F':|RejectErrorConditions>|WriteMode' '{print $1 $3, $5}'| sed -e 's/<\/RejectErrorCondition>//g' -e 's/\x27/ /g' -e 's/<RejectErrorCondition type= int >//g' -e 's/<\///g' -e 's/modified= 1  type= int ><!//g' -e 's/dsx/dsx RJ/g' -e 's/\[CDATA\[/ WM/g' -e 's/]]>//g' -e 's/type= int ><!//g' > conditionsettings
