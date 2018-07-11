#!/bin/bash

# Print error and msg of fail
# @params
# 1: error code
# @: message
# @return
# exit of script
failMessage()
{
	error_code="$1"
	shift 1
	log_date=$(date -R)
	error_message="[minecraft-dnsrotator] $log_date #Error code: ${error_code}# $@"
	echo $error_message | systemd-cat -p warning
	echo "$error_message"
	exit $error_code
}

# Get _minecraft._tcp.domain TXT record
# @params
# 1: domain
# @return
# TXT record content
getTxtRecord()
{
	domain=$1
	result=$(host -t srv _minecraft._tcp.${domain})

	count_result=$(echo $result | awk 'END{print _}{_+=NF-1}' FS="has SRV record")

	if [ $count_result -ne "1" ]
	then
		failMessage 1 "Multiple _minecraft._tcp.DOMAIN records not supported yet or tcp connection did not work"
	else
		record=$(echo $result | cut -d" " -f8 | sed 's/\.$//')
		echo $record
	fi	
}

# Get JSON domain info
# @params
# 1: domain
# @return
# -1 if curl failed or json domain info
getJsonDomainInfo()
{
	domain=$1
	url_api="https://use.gameapis.net/mc/extra/blockedservers/check/"

	result=$(curl -s ${url_api}/$domain)
	curl_code=$?

	if [ $curl_code -ne "0" ]
	then
		failMessage 2 "Curl failed with >> $curl_code << curl code"
	else
		echo $result
	fi
}

# Verify if _minecraft._tcp.DOMAIN content is blocked
# @parmans
# 1: domain
# @return
# 1 if blocked, 0 if unblocked
checkIfBlocked()
{
	domain=$1
	domain_json_info=$(getJsonDomainInfo $domain)
	domain_srv_record=$(getTxtRecord $domain)
	domain_json_txt_record=$(echo $domain_json_info | jq --arg domain "$domain" '.[$domain]' | jq --arg domain2 "$domain_srv_record" '.[] | select(.domain==$domain2)')
	domain_json_blocked=$(echo $domain_json_txt_record | jq '.blocked')

	if [[ "$domain_json_blocked" == "true" ]]
	then
		echo 1
	else
		echo 0
	fi
}

# Get subdomain to update DNS record
# @params
# 1: domain
# @return
# subdomain
getNewSrvFromConf()
{
	domain=$1
	result=$(cat $conf_domains_unused | egrep -iv "^#" | egrep -m 1 $domain | cut -d";" -f1)

	if [[ "${result}x" == "x" ]]
	then
		failMessage 3 "No more subdomains (srv records) to use with domain >> $domain <<."
	else
		echo $result 
	fi
}


# Get Zone Identifier
# @params
# 1: domain
# 2: cloudflare_authkey
# 3: cloudflare_email
# @return
# identifier if success, error code if not
cloudflareZoneIdentifier()
{
	domain=$1
 	cloudflare_authkey=$2
	cloudflare_email=$3
	zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" -H "X-Auth-Email: $cloudflare_email" -H "X-Auth-Key: $cloudflare_key" -H "Content-Type: application/json")
	curl_code=$?

	if [ $curl_code -ne "0" ]
	then
		failMessage 5 "Curl from cloudflareZoneIdentifier() failed"
	else
		json_success=$(echo $zone_identifier | jq '.success')
		if [[ $json_sucess == "false" ]]
		then
			failMessage 6 "Clouflare JSON replied no success on get Zone Identifier >> $domain <<"
		else
			zone_identifier=$(echo $zone_identifier | jq '.result[0].id' | tr -d "\"")
			echo $zone_identifier
		fi
	fi
}

# Get Record Identifier
# @params
# 1: domain
# 2: cloudflare authkey
# 3: cloudflare email
# 4: zone identifier
# @return
# identifier if success, error code if not
cloudflareRecordIdentifier()
{
	domain=$1
 	cloudflare_authkey=$2
	cloudflare_email=$3
	zone_identifier=$4
	record_name="_minecraft._tcp.${domain}"
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $cloudflare_email" -H "X-Auth-Key: $cloudflare_key" -H "Content-Type: application/json")
	curl_code=$?

	if [ $curl_code -ne "0" ]
	then
		failMessage 7 "Curl from cloudflareRecordIdentifier() failed"
	else
	json_success=$(echo $record_identifier | jq '.success')
		if [[ $json_sucess == "false" ]]
		then
			failMessage 8 "Clouflare JSON replied no success on Record Identifier >> $domain <<"
		else
			record_identifier=$(echo $record_identifier | jq '.result[0].id' | tr -d "\"")
			echo $record_identifier
		fi
	fi
}
 
# Update a SRV record from indicated domain
# @params
# 1: domain
# @return
# 0 if success, exit with error cod if not
cloudflareUpdateSrv()
{
	domain=$1
	result=$(cat $conf_cloudflare | egrep -iv "^#" | egrep -m 1 $domain)

	if [[ "${result}x" == "x" ]]
	then
		failMessage 4 "No credentials to update >> $domain << on cloudflare."
	else
 		cloudflare_authkey=$(echo $result | cut -d";" -f1)
		cloudflare_email=$(echo $result | cut -d";" -f2)
		cloudflare_zoneid=$(echo $result | cut -d";" -f3)
		new_dns=$(getNewSrvFromConf $domain)
		zone_identifier=$(cloudflareZoneIdentifier $domain $cloudflare_authkey $cloudflare_email)
		record_identifier=$(cloudflareRecordIdentifier $domain $cloudflare_authkey $cloudflare_email $zone_identifier)
		
		curl -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
	    -H "X-Auth-Email: $cloudflare_email" \
   		-H "X-Auth-Key: $cloudflare_authkey" \
	    -H "Content-Type: application/json" \
		--data '{"zone_name":"'$domain'","zone_id":"'$zone_identifier'","type":"SRV","name":"minecraft._tcp."'$domain'".","content":"SRV 1 1 25565 "'$new_dns'".","data":{"priority":1,"weight":1,"port":25565,"target":"'$new_dns'","service":"_minecraft","proto":"_tcp","name":"'$domain'"},"proxied":false,"proxiable":false,"ttl":1,"priority":1}'
		curl_code=$?
		
		if [ $curl_code -ne 0 ]
		then
			failMessage 9 "Failed to write new SRV record"
		else
			sed -i "/^${new_dns}/d" $conf_domains_unused
		fi
	fi
}

# global vars
conf_path=/etc/minecraftdnsrotator/
conf_cloudflare=$conf_path/credentials-cloudflare.conf
conf_domains_unused=$conf_path/domains-unused.conf
conf_domains_blocked=$conf_path/domains-blocked.conf

# main script
domain=$1

domain_check=$(checkIfBlocked $domain)

if [ $domain_check -eq "1" ]
then
	cloudflareUpdateSrv $domain
fi
