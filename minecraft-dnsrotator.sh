#!/bin/bash

# Get _minecraft._tcp.domain TXT record
# @params
# 1: domain
# @return
# -1 if failed or TXT record content
getTxtRecord()
{
	domain=$1
	result=$(host -t srv _minecraft._tcp.${domain})

	count_result=$(echo $result | awk 'END{print _}{_+=NF-1}' FS="has SRV record")

	if [ $count_result -ne "1" ]
	then
		# Multiple _minecraft._tcp.DOMAIN records not supported yet or tcp connection did not work
		echo -1
	else
		record=$(echo $result | cut -d" " -f8 | sed 's/\.$//')
		echo $record
	fi	
}

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
		echo -1
	else
		echo $result
	fi
}
