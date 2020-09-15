#!/bin/dash
# template-base.sh - The base plate for the entire site
#
# * Input
#   - env KOBUGI_*: the Kobugi interface
#   - stdin: page content
#
# * Output
#   - stdout: generated page
#
# * Related
#   - /global.css: site-global stylesheet
#   - local.css, local.js: local stylesheet and script
#   - SKOBUGI_SRC: link to original file
#
# This is the outer-most wrapper for any content in the site.
#

set -e

if [ -z "$KOBUGI_PWD" ]; then
	echo "This script can't run independently." >&2
fi

tmp=$(mktemp)
trap cleanup EXIT
cleanup() {
	rm -f "$tmp"
}

case "$KOBUGI_PWD:$KOBUGI_DEST" in
	/:index.html) title="Hyunmu.am" ;;
	/:*         ) title="/${KOBUGI_DEST} - Hyunmu.am" ;;
	*:index.html) title="${KOBUGI_PWD}/ - Hyunmu.am" ;;
	*:*         ) title="${KOBUGI_PWD}/${KOBUGI_DEST} - Hyunmu.am" ;;
esac


add_local_res() {
	[ -f local.css ] && echo '  <link rel="stylesheet" href="local.css" />' || true
	[ -f local.js ] && echo '  <script src="local.js"></script>' || true
}

add_topbar() {
	local -
	if [ "$KOBUGI_DEST" = "index.html" ]; then
		if [ "$KOBUGI_PWD" = '/' ]; then
			goup=''
		else
			goup='<a href="../" class="tpl-goup">⇧ Go Up</a>'
		fi
		down=''
	else
		goup='<a href="./" class="tpl-goup">⇧ Go Up</a>'
		down="<a href=\"$KOBUGI_SRC\" download>⇩ Download</a>"
	fi

	down_url=""

	cat <<- EOF
	<nav class="tpl-top">
	  <div class="tpl-top-inner">
	    ${goup}
	    ${down}
	  </div>
	</nav>
	EOF
}


cat > "$tmp" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <link rel="stylesheet" href="/global.css" />
$(add_local_res)
</head>

<body>
$(add_topbar)
$(cat)
</body>
</html>
EOF

mv "$tmp" "$KOBUGI_DEST"
