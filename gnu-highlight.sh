#!/bin/dash
# gnu-highlight.sh - A recipe script for `gnu-highlight` plugin for Kobugi.
#
# This script not only highlights the given code, but also inserts <span> tags
# w/ line number IDs for hash(#) linking.
#
# Input:
#   - ${KOBUGI_INPUT}: the source code.
#
# Output:
#   - ${KOBUGI_OUTPUT}: the highlighted code w/ line number tags.
#

set -euf

buf="$(mktemp)"

class="hl l"
prefix="L"

count=''

highlight --replace-tabs=4 --no-doc --enclose-pre "$KOBUGI_INPUT" |
cat -n |
sed "$( cat <<- EOF
	s/^\s*\([0-9]\+\)\t\(.*<pre[^>]*>\)\(.*\)$/\2<span class="${class}" id="${prefix}_\1">\3<\/span>/;
	t;
	s/^\s*\([0-9]\+\)\t\(.*\)<\\/pre>/<\\/span><\\/pre>/;
	t;
	s/^\s*\([0-9]\+\)\t\(.*\)$/<span class="${class}" id="${prefix}_\1">\2<\\/span>/
EOF
)" > "$KOBUGI_OUTPUT"
