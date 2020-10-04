#!/bin/dash
# template.sh - The default template for Kobugi
#
# * Input
#   - env KOBUGI_*: the Kobugi interface
#   - ${KOBUGI_INPUT}: page content
#   - kobugimap(.htmp): (optional) directory entries
#
# * Output
#   - ${KOBUGI_OUTPUT}: generated page
#
# * Related
#   - /global.css: site-global stylesheet
#   - local.css, local.js: local stylesheet and script
#
# This is the outer-most wrapper for any content in the site.
#

set -euf

if [ -z "$KOBUGI_CWD" ]; then
	echo "This script can't run independently." >&2
fi

tmp=$(mktemp)
trap cleanup EXIT
cleanup() {
	rm -f "$tmp"
}

case "$KOBUGI_CWD:$KOBUGI_OUTPUT" in
	/:index.html) title="Hyunmu.am" ;;
	/:*         ) title="/${KOBUGI_OUTPUT} - Hyunmu.am" ;;
	*:index.html) title="${KOBUGI_CWD}/ - Hyunmu.am" ;;
	*:*         ) title="${KOBUGI_CWD}/${KOBUGI_OUTPUT} - Hyunmu.am" ;;
esac

header() {
	url_up=''
	url_down=''
	case "$KOBUGI_CWD:$KOBUGI_OUTPUT" in
		/:index.html) ;;
		*:index.html) url_up='../' ;;
		*)
			url_up='./'
			if [ -n "$KOBUGI_INPUT" -a -f "$KOBUGI_INPUT" ]; then
				url_down="$KOBUGI_INPUT"
			fi
			;;
	esac

	cat <<- EOF
	<header>

	<div id="HeaderLeftSlot"></div>

	<div id="HeaderLinks">
	<nav>
	EOF

	[ -n "$url_up" ] && cat <<- EOF
	  <span class="LinkUp">
	    <a href="$url_up">⇧ Up</a>
	  </span
	EOF

	[ -n "$url_down" ] && cat <<- EOF
	  <span class="LinkDown">
	    <a href='$KOBUGI_INPUT' download>⇩ Download</a>
	  </span
	EOF

	cat <<- EOF
	</nav>
	</div>

	<div id="HeaderRightSlot"></div>

	</header>
	EOF
}

footer() {
	cat <<- EOF
	<footer>
	  <span>generated with Kobugi</span>
	</footer>
	EOF
}

{

cat <<- EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <link rel="stylesheet" href="/global.css" />$(
	[ ! -f local.css ] || echo '  <link rel="stylesheet" href="local.css" />'
	[ ! -f local.js  ] || echo '  <script src="local.js"></script>'
)
</head>

<body class="Kobugi">
<div id="Body">

<div id="Header">
$(header)
</div>

EOF

if [ -f "$KOBUGI_INPUT" ]; then
	cat <<- EOF
	<div id="Main">
	$(cat "$KOBUGI_INPUT")
	</div>

	EOF
fi

# TODO: use environment variable for the filename of the map?
if [ "$KOBUGI_OUTPUT" = 'index.html' -a -f kobugimap.htmp ]; then
	cat <<- EOF
	<div id="Index">
	<nav>
	$(cat kobugimap.htmp)
	</nav>
	</div>

	EOF
fi

cat <<- EOF
<div id="Footer">
$(footer)
</div>

</div>
</body>
</html>
EOF

} > "$tmp"

mv "$tmp" "$KOBUGI_OUTPUT"
