#!/bin/dash
# template-index.sh - generates directory index content
#
# * Input
#   - env KOBUGI_*: the Kobugi interface
#   - $1: (optional) a file containing index header
#   - kobugimap: (optional) index entry information
#
# * Output
#   - ${KOBUGI_OUTPUT}
#
# * Related
#   - */, *.html: links to local directories and pages
#
set -euf

header_file="$1"

rm -f "$KOBUGI_OUTPUT"
exec >"$KOBUGI_OUTPUT"

if [ -f "$header_file" ]; then
	cat <<- EOF
		<div id="IndexHeader">
		$(cat "$header_file")
		</div>
	EOF
fi

cat <<- EOF
	<div id="IndexEntries">
	$("$KOBUGI_LIB/genindex.sh")
	</div>
EOF
