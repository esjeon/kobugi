#!/bin/dash
# genindex.sh - generate index entries based on kobugimap
#
# * Input
#   - ${KOBUGI_INPUT}: content
#   - ./kobugimap: index entries
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
set -eu

tab='	'

tmp="$(mktemp -d)"
trap cleanup EXIT
cleanup() {
	rm -rf "$tmp"
}

verify_entry() {
	# $1: name

	case "$1" in
		*/*) return 1 ;;
	esac

	[ -d "$1" ] || [ -f "$1.html" ] || return 1
}

print_entry() {
	# $1: file/URL
	# $2: display name
	# $3: description

	cat <<- EOF
	  <div class="Entry">
	    <span class="Name"><a href="$1">$2</a></span>
	    <span class="Description">$3</span>
	  </div>
	EOF
}

mark_entry() {
	touch "${tmp}/${1}"
}

is_entry_marked() {
	[ -f "${tmp}/${1}" ] || return 1
}

print_rest() {
	# no arguments

	for dir in */; do
		[ -d "$dir" ] || continue

		name="${dir%/}"
		is_entry_marked "$name" && continue

		print_entry "$dir" "$name" ""
	done

	for html in *.html; do
		[ -f "$html" ] || continue

		if [ "$html" = 'index.html' ]; then
			continue
		fi

		name="${html%.html}"
		is_entry_marked "$name" && continue

		print_entry "$html" "$name" ""
	done
}

{
	if [ -f "$KOBUGI_INPUT" ]; then
		cat <<- EOF
			<div id="IndexContent">
			$(cat "$KOBUGI_INPUT")
			</div>

		EOF
	fi

	cat <<- EOF
	<div id="Index">
	<nav>
	EOF

	if [ -f kobugimap ]; then
		cat kobugimap | while IFS="$tab" read -r arg0 arg1 arg2 arg3 arg4; do
			case "$arg0" in
				'') ;;
				'#'*) ;;

				rest)
					print_rest ;;

				separator)
					cat <<- EOF
					  <hr class="Separator"/>
					EOF
					;;

				text)
					cat <<- EOF
					  <div class="Text">
						$arg1
					  </div>
					EOF
					;;

				title)
					cat <<- EOF
					  <div class="Title">
						<h2>$arg1</h2>
					  </div>
					EOF
					;;

				entry)
					verify_entry "$arg1" || continue
					is_entry_marked "$arg1" && continue
					print_entry "$arg1" "$arg2" "$arg3"
					mark_entry "$arg1" ;;

				link)
					print_entry "$arg1" "$arg2" "$arg3" ;;

				*)
					echo "wtf: $arg0/$arg1/$arg2/$arg3/$arg4" >&2 ;;
			esac
		done 
	else
		print_rest
	fi

	cat <<- EOF
	</nav>
	</div>
	EOF
} > "${KOBUGI_OUTPUT}"
