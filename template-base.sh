#!/bin/dash

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
	[ "$KOBUGI_DEST" = "index.html" ] && return || true
	
	local file
	file="${KOBUGI_DEST%.html}"

	cat <<- EOF
	<nav class="tpl-top">
	  <a href=".." class="tpl-goup">⇧</span>
	  <span class="tpl-name"></span>
	  <a href="$file" download>Original</a>
	</nav>
	EOF
}


cat > "$tmp" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
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
