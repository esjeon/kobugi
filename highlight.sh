#!/bin/dash

set -e

file="$1"

class="hl l"
prefix="L"

count=''

(
	highlight --replace-tabs=4 --no-doc --enclose-pre "$file"
	echo
) | \
while read line; do
	case "$line" in
		'<pre '*)
			echo "$line" | sed "
				s/>/><span class='${class}' id='${prefix}1'>/
				s/\$/<\/span>/
			"
			count=2
			;;
		'</pre>')
			echo "$line"
			count=''
			;;
		*'</pre>')
			echo "$line" | sed "
				s/^/<span class='${class}' id='${prefix}${count}'>/
				s/<\/pre>/<\/span><\/pre>/
			"
			count=''
			;;
		*)
			if [ -n "$count" ]; then
				echo "<span class='${class}' id='${prefix}${count}'>${line}</span>"
				count=$((count + 1))
			else
				echo "$line"
			fi
			;;
	esac
done

