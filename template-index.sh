#!/bin/dash
set -xe

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

mkdir -p "${tmp}/desc"
set_entry_desc() {
	echo -n "$2" > "${tmp}/desc/${1%/}"
}
get_entry_desc() {
	if [ -e "${tmp}/desc/${1%/}" ]; then
		cat "${tmp}/desc/${1%/}"
	fi
}


mkdir -p "${tmp}/altname"
set_entry_altname() {
	echo -n "$2" > "${tmp}/altname/${1%/}"
}
get_entry_altname() {
	if [ -e "${tmp}/altname/${1%/}" ]; then
		cat "${tmp}/altname/${1%/}"
	fi
}


mkdir -p "${tmp}/skip"
set_skip_entry() {
	touch "${tmp}/skip/${1%/}";
}
should_skip_entry() {
	[ -e "${tmp}/skip/${1%/}" ] || return 1
}


touch "${tmp}/entries"
append_item() {
	echo "${1%/}" >> "${tmp}/entries"
}
append_content() {
	echo '#content' >> "${tmp}/entries"
}
get_first_item() {
	head -n1 "${tmp}/entries"
}


mark_content_printed() {
	touch "${tmp}/content_printed"
}
is_content_printed() {
	[ -e "${tmp}/content_printed" ] || return 1
}


#
# Save STDIN to a file
#

cat > "${tmp}/content"
if [ ! -s "${tmp}/content" ]; then
	echo "${KOBUGI_DEST%.html}" > "${tmp}/content"
fi


#
# Define DSL and run the given ***map*** file
#

if [ -f "$mapfile" ]; then
(
	entry() {
		local entry
		if [ -d "${1%/}" ]; then
			entry="${1%/}/"
		elif [ -f "$1.html" ]; then
			entry="$1.html"
		else
			return 1
		fi

		append_item "$entry"
		[ -n "$2" ] && set_entry_altname "$entry" "$2" || true
		[ -n "$3" ] && set_entry_desc "$entry" "$3" || true
	};

	content() {
		append_content
	};

	## `ignore` makes the given entry excluded from the index
	ignore() {
		set_skip_entry "${1}.html"
	};

	. ./"$mapfile"
)
fi

#
# Map-info post-processing
#

# Append all the files in the working directory to the item list.
# (Entries will be handled only once.)
(
	ls -d */ || true;
	ls *.html || true;
) >> "${tmp}/entries" 2>/dev/null


# split entries list
(
	while read item; do
		[ "$item" = '#content' ] && break || true
		[ "$item" = 'index.html' ] && continue || true

		echo "$item"
	done > "${tmp}/entries-above"

	while read item; do
		[ "$item" = '#content' ] && continue || true
		[ "$item" = 'index.html' ] && continue || true
		echo "$item"
	done > "${tmp}/entries-below"
) < "${tmp}/entries"


#
# Generate the output
#

print_entry() {
	local -
	entry="${1%/}"

	should_skip_entry "$entry" \
		&& return 0 \
		|| set_skip_entry "$entry"

	[ -d "$entry" ] \
		&& dir='idx-dir' \
		|| dir=''

	name="$(get_entry_altname "${entry}")"
	if [ -z "$name" ]; then
		name="${entry%.html}"
	fi

	desc="$(get_entry_desc "$entry")"

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

