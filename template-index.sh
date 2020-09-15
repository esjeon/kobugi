#!/bin/dash
# template-index.sh - generates directory index content
#
# * Input
#   - env KOBUGI_*: the Kobugi interface
#   - stdin: index prose
#   - $1: path to index map file (i.e index.map)
#
# * Output
#   - stdout: generated index content
#
# * Related
#   - */, *.html: links to local directories and pages
#
set -e

mapfile="$1"


#
# Create temporary storage
#

tmp="$(mktemp -d)"
trap _cleanup EXIT
_cleanup() { rm -rf "$tmp"; }


#
# Data model
#

map_init() {
	# $1 = map name
	mkdir -p "${tmp}/map-$1"
}
map_set() {
	# $1 = map name
	# $2 = key
	# $3 = value
	echo -n "$3" > "${tmp}/map-$1/$2"
}
map_get() {
	# $1 = map name
	# $2 = key
	cat "${tmp}/map-$1/$2" 2>/dev/null || return 0
}

map_init desc
map_init disp
map_init skip

should_skip_entry() {
	# $1 = entry name
	[ "$(map_get skip "$1")" = 1 ] || return 1
}

touch "${tmp}/entries"
append_entry() {
	echo "$1" >> "${tmp}/entries"
}
append_content() {
	echo '#content' >> "${tmp}/entries"
}
print_entries() {
	cat "${tmp}/entries"
}


#
# Save STDIN to a file
#

cat > "${tmp}/content"
if [ ! -s "${tmp}/content" ]; then
	echo "<h1>${KOBUGI_PWD}</h1>" > "${tmp}/content"
fi


#
# Define DSL and run the given ***map*** file
#

if [ -f "$mapfile" ]; then
(
	entry() {
		# $1 = name
		# $2 = display name
		# $3 = description

		local entry
		if [ -d "$1" ]; then
			entry="${1%/}"
		elif [ -f "$1.html" ]; then
			entry="$1.html"
		else
			return 1
		fi

		append_entry "$entry"
		[ -n "$2" ] && map_set disp "$entry" "$2" || true
		[ -n "$3" ] && map_set desc "$entry" "$3" || true
	};

	content() {
		append_content
	};

	## `ignore` makes the given entry excluded from the index
	ignore() {
		map_set skip "$1.html" 1
	};

	. ./"$mapfile"
)
fi

#
# Map-info post-processing
#

# Append all the files in the working directory to the entry list.
# (Entries will be handled only once.)
(
	ls -d */ || true;
	ls *.html || true;
) 2>/dev/null | sed 's/\/$//' >> "${tmp}/entries"

# split entries list
cat "${tmp}/entries" |
(
	while read entry; do
		[ "$entry" = '#content' ] && break || true
		[ "$entry" = 'index.html' ] && continue || true

		echo "$entry"
	done > "${tmp}/entries-above"

	while read entry; do
		[ "$entry" = '#content' ] && continue || true
		[ "$entry" = 'index.html' ] && continue || true
		echo "$entry"
	done > "${tmp}/entries-below"
)

# If the map doesn't specify, the index should go below the content
if ! grep -q '#content' "${tmp}/entries"; then
	mv "${tmp}/entries-above" "${tmp}/entries-below"
	touch "${tmp}/entries-above"
fi


#
# Generate the output
#

print_entry() {
	# $1 = entry name
	local -

	entry="$1"

	should_skip_entry "$entry" \
		&& return 0 \
		|| map_set skip "$entry" 1

	[ -d "$entry" ] \
		&& dir='idx-dir' \
		|| dir=''

	name="$(map_get disp "${entry}")"
	if [ -z "$name" ]; then
		name="${entry%.html}"
	fi

	desc="$(map_get desc "$entry")"

	cat <<- EOF
		  <div class="idx-i ${dir}">
		    <div class="idx-name">
		      <a href="${entry}">${name}</a>
		    </div>
		    <div class="idx-desc">${desc}</div>
		  </div>
	EOF
}

print_entries() {
	entries="${tmp}/entries-$1"
	[ -s "$entries" ] || return 0

	cat <<- EOF
		<nav class="idx idx-$1">
	EOF

	while read entry; do
		print_entry "$entry";
	done < "$entries"

	cat <<- EOF
		</nav>
	EOF
}

cat <<- EOF_PAGE
	$(print_entries "above")

	<article class="idx-content">
	$( cat "${tmp}/content" )
	</article>

	$(print_entries "below")
EOF_PAGE

