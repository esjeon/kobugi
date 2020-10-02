#!/bin/dash
# genindex.sh - generate index entries based on kobugimap
#
# * Input
#   - ${KOBUGI_INPUT}: content
#   - ${KOBUGI_ASSETS}: list of asset files in CWD
#   - ./kobugimap: index entries
#
# * Output
#   - ${KOBUGI_OUTPUT}: generated page
#
set -eu

tab='	'

tmp="$(mktemp -d)"
trap cleanup EXIT
cleanup() {
	rm -rf "$tmp"
}

# Print the actual file name of the given "entry" to stdout.
#
# An entry can be either:
#   - a directory named "$entry"
#   - a file named "$entry"
#   - a page named "${entry}.html"
#
# If the given entry is invalid, nothing will be printed.
normalize_name() {
	# $1: name

	case "$1" in
		*/*) return ;;
	esac

	if [ -d "$1" ]; then
		echo "$1"
	elif [ -f "$1" ]; then
		echo "$1"
	elif [ -f "$1.html" ]; then
		echo "$1.html"
	fi
}

detect_class() {
	# $1: VALID filename

	if [ -d "$1" ]; then
		echo "Dir"
	else
		case "$1" in
			*.html) echo "Page" ;;
			*) echo "Asset" ;;
		esac
	fi
}

print_entry() {
	# $1: filename/URL
	# $2: display name
	# $3: description
	# $4: class (Dir, Page, Asset, Link)
	local url disp desc cls down
	url="$1"
	disp="${2:-$url}"
	desc="$3"
	cls=" $4"

	if [ "$cls" = " Asset" ]; then
		down=" download"
	else
		down=''
	fi

	cat <<- EOF
	  <div class="Entry${cls}">
	    <span class="Name"><a href="${url}"${down}>${disp}</a></span>
	    <span class="Description">${desc}</span>
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
	local name

	for dir in */; do
		[ -d "$dir" ] || continue

		name="${dir%/}"
		is_entry_marked "$name" && continue

		print_entry "$dir" "$name" "" "Dir"
	done

	for html in *.html; do
		[ -f "$html" ] || continue

		if [ "$html" = 'index.html' ]; then
			continue
		fi

		is_entry_marked "$html" && continue

		print_entry "$html" "${html%.html}" "" "Page"
	done

	for asset in ${KOBUGI_ASSETS}; do
		[ -f "$asset" ] || continue

		is_entry_marked "$asset" && continue

		print_entry "$asset" "$asset" "" "Asset"
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
		cat kobugimap | while IFS="$tab" read arg0 arg1 arg2 arg3 arg4; do
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
					name="$(normalize_name $arg1)"
					[ -z "$name" ] && exit 1

					is_entry_marked "$name" && continue
					mark_entry "$name"

					cls="$(detect_class "$name")"
					print_entry "$name" "$arg2" "$arg3" "$cls"
					;;

				link)
					print_entry "$arg1" "$arg2" "$arg3" "Link"
					;;

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
} > "${tmp}/buf"

mv "${tmp}/buf" "${KOBUGI_OUTPUT}"
