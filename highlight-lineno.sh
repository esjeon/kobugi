#!/bin/dash

sed -e '
	/^<pre / {
		s/>/><span class="hl l">/;
		s/$/<\/span>/;
		p; d
	};
	/^<\/pre>/ {
		p; d
	};
	s/^/<span class="hl l">/;
	s/$/<\/span>/
'
