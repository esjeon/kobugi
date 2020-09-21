#!/bin/dash
# gnu-highlight.sh - A recipe script for `gnu-highlight` plugin for Kobugi.
#
# This script not only highlights the given code, but also inserts <span> tags
# w/ line number IDs for hash(#) linking.
#
# Input:
#   - $1: the path to a source code
#
# Output:
#   - STDOUT: the highlighted code w/ line number tags.
#

set -e

file="$1"

class="hl l"
prefix="L"

count=''

highlight --replace-tabs=4 --no-doc --enclose-pre "$file" |
cat -n |
sed "$( cat <<- EOF
	s/^\s*\([0-9]\+\)\t\(.*<pre[^>]*>\)\(.*\)$/\2<span class="${class}" id="${prefix}_\1">\3<\/span>/;
	t;
	s/^\s*\([0-9]\+\)\t\(.*\)<\\/pre>/<\\/span><\\/pre>/;
	t;
	s/^\s*\([0-9]\+\)\t\(.*\)$/<span class="${class}" id="${prefix}_\1">\2<\\/span>/
EOF
)"
