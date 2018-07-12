#!/bin/bash

echo "Did you update de git? (yes|y) to proceed, other thing to exit"
read answer

if echo $answer | egrep -qi "(y|yes)"
then
	cp minecraft-dnsrotator.sh /usr/bin/minecraft-dnsrotator.sh
	chmod +x /usr/bin/minecraft-dnsrotator.sh
	echo "Updated."
fi
