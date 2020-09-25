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
	  <div class="IndexEntry">
	    <span class="Name"><a href="$1">$2</a></span>
	    <span class="Description">$3</span>
	  </div>
	EOF
}

print_rest() {
	# no arguments

	for dir in */; do
		[ -d "$dir" ] || continue

		name="${dir%/}"
		print_entry "$dir" "$name" ""
	done

	for html in *.html; do
		[ -f "$html" ] || continue

		if [ "$html" = 'index.html' ]; then
			continue
		fi

		name="${html%.html}"
		print_entry "$html" "$name" ""
	done
}

{
	if [ -f "$KOBUGI_INPUT" ]; then
		cat <<- EOF
			<div id="IndexHeader">
			$(cat "$KOBUGI_INPUT")
			</div>

		EOF
	fi

	cat <<- EOF
	<div id="IndexEntries">
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
					echo "  <hr/>" ;;

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
					verify_entry "$arg1"
					print_entry "$arg1" "$arg2" "$arg3" ;;

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
