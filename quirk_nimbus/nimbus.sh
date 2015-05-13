#!/bin/bash
#
# Author: Matt Marich
# Date: 5-13-15
#
# Pulls information that was sent to files in tmp from another curl script, sends information to nimbus device
#

# Since we need to wait for cron'd curl to finish prior to this being ran, there is a short sleep delay
sleep 10

count=0
counter=0

while read line
do
        counter=$[$counter+1]
        cleaned=`echo $line | cut -d '/' -f 1`
        if [[ "$cleaned" == *"KB" ]]; then
                speed=`echo $cleaned | cut -d ' ' -f 1`
                conversion=`echo "scale=2; $speed/1024" | bc`
                sizeinmb="0$conversion MB"
        else
                sizeinmb="$cleaned"
        fi

        sizereturn[$counter]=$sizeinmb
        noletters[$counter]=`echo ${sizereturn[$counter]} | cut -d ' ' -f 1`
done < /tmp/temp2

dial1label=`echo "scale = 0; ${noletters[1]} * 8" | bc`
dial2label=`echo "scale = 0; ${noletters[2]} * 8" | bc`
dial3label=`cat /tmp/temp3`

dial1=0
dial2=0
dial3=0

curlrequest=`curl --include \
     --request POST \
     --header "Content-Type: application/json" \
     --data-binary '{
    "client_id": "<wink_api_client_id_here>",
    "client_secret": "<wink_api_secret_here>",
    "username": "<user_name_here>",
    "password": "<password_here>",
    "grant_type": "password"
}' \
     'https://winkapi.quirky.com/oauth2/token'` 

echo ""
echo $curlrequest
echo ""

accesstoken=`echo $curlrequest | grep 'access_token' | cut -d '{' -f 3 | cut -d '"' -f 4`
refreshtoken=`echo $curlrequest | grep 'access_token' | cut -d '{' -f 3 | cut -d '"' -f 8`

curl --include \
     --request PUT \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $accesstoken" \
     --data-binary '{"label":"DO:'$dial1label'","channel_configuration":{"channel_id":"10"}}' \
     'https://winkapi.quirky.com/dials/<dial_1_id>'

curl --include \
     --request PUT \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $accesstoken" \
     --data-binary '{"label":"XL:'$dial2label'","value":'$dial2',"channel_configuration":{"channel_id":"10"}}' \
     'https://winkapi.quirky.com/dials/<dial_2_id>'

curl --include \
     --request PUT \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $accesstoken" \
     --data-binary '{"label":"TWT:'$dial3label'","value":'$dial3',"channel_configuration":{"channel_id":"10"}}' \
     'https://winkapi.quirky.com/dials/<dial_3_id>'

exit 0
