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
	curl_code=$(echo $?)

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

	if [[ "$domain_json_blocked" == "true"]]
		echo 1
	else
		echo 0
	fi
}
