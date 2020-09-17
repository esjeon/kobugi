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

if [ -z "$KOBUGI_CWD" ]; then
	echo "This script can't run independently." >&2
fi

tmp=$(mktemp)
trap cleanup EXIT
cleanup() {
	rm -f "$tmp"
}

case "$KOBUGI_CWD:$KOBUGI_DEST" in
	/:index.html) title="Hyunmu.am" ;;
	/:*         ) title="/${KOBUGI_DEST} - Hyunmu.am" ;;
	*:index.html) title="${KOBUGI_CWD}/ - Hyunmu.am" ;;
	*:*         ) title="${KOBUGI_CWD}/${KOBUGI_DEST} - Hyunmu.am" ;;
esac

header() {
	url_up=''
	url_down=''
	case "$KOBUGI_CWD:$KOBUGI_DEST" in
		/:index.html) ;;
		*:index.html) url_up='../' ;;
		*)
			url_up='./'
			if [ -n "$KOBUGI_SRC" -a -f "$KOBUGI_SRC" ]; then
				url_down="$KOBUGI_SRC"
			fi
			;;
	esac

	cat <<- EOF
	<nav>
	  <div class="HeaderLinks">
	EOF

	[ -n "$url_up" ] && cat <<- EOF
	    <span class="LinkUp">
	      <a href="$url_up">⇧ Up</a>
	    </span
	EOF

	[ -n "$url_down" ] && cat <<- EOF
	    <span class="LinkDown">
	      <a href='$KOBUGI_SRC' download>⇩ Download</a>
	    </span
	EOF

	cat <<- EOF
	  </div>
	</nav>
	EOF
}

body () {
	cat
}

footer() {
	cat <<- EOF
	<footer>
	  <span>generated with Kobugi</span>
	</footer>
	EOF
}


cat > "$tmp" << EOF
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

<div id="Main">
$(body)
</div>

<div id="Footer">
$(footer)
</div>

</div>
</body>
</html>
EOF

mv "$tmp" "$KOBUGI_DEST"
