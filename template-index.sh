#!/bin/bash
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

declare -A entryDesc
set_entry_desc() {
	# $1 = entry name
	# $2 = description
	entryDesc[$1]="$2"
}
get_entry_desc() {
	# $1 = entry name
	echo -n "${entryDesc[$1]}"
}

declare -A entryDisp
set_entry_dispname() {
	# $1 = entry name
	# $2 = display name
	entryDisp[$1]="$2"
}
get_entry_dispname() {
	# $1 = entry name
	echo -n "${entryDisp[$1]}"
}

declare -A entrySkip
set_skip_entry() {
	# $1 = entry name
	entrySkip[$1]=1
}
should_skip_entry() {
	# $1 = entry name
	[[ "${entrySkip[$1]}" -eq 1 ]] || return 1
}

touch "${tmp}/entries"
append_entry() {
	echo "${1%/}" >> "${tmp}/entries"
}
append_content() {
	echo '#content' >> "${tmp}/entries"
}
print_entries() {
	cat "${tmp}/entries"
}


mark_content_printed() {
	touch "${tmp}/content_printed"
}
is_content_printed() {
	[[ -e "${tmp}/content_printed" ]] || return 1
}


#
# Save STDIN to a file
#

cat > "${tmp}/content"
if [[ ! -s "${tmp}/content" ]]; then
	echo "${KOBUGI_DEST%.html}" > "${tmp}/content"
fi


#
# Define DSL and run the given ***map*** file
#

if [[ -f "$mapfile" ]]; then
(
	entry() {
		# $1 = name
		# $2 = display name
		# $3 = description

		local entry
		if [[ -d "${1%/}" ]]; then
			entry="${1%/}/"
		elif [[ -f "$1.html" ]]; then
			entry="$1.html"
		else
			return 1
		fi

		append_entry "$entry"
		[[ -n "$2" ]] && set_entry_dispname "$entry" "$2" || true
		[[ -n "$3" ]] && set_entry_desc "$entry" "$3" || true
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

# Append all the files in the working directory to the entry list.
# (Entries will be handled only once.)
(
	ls -d */ || true;
	ls *.html || true;
) >> "${tmp}/entries" 2>/dev/null


# split entries list
(
	while read entry; do
		[[ "$entry" = '#content' ]] && break || true
		[[ "$entry" = 'index.html' ]] && continue || true

		echo "$entry"
	done > "${tmp}/entries-above"

	while read entry; do
		[[ "$entry" = '#content' ]] && continue || true
		[[ "$entry" = 'index.html' ]] && continue || true
		echo "$entry"
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

	[[ -d "$entry" ]] \
		&& dir='idx-dir' \
		|| dir=''

	name="$(get_entry_dispname "${entry}")"
	if [[ -z "$name" ]]; then
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
	[[ -s "$entries" ]] || return 0

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

