#!/bin/sh
#
# USAGE:   generate-webdocs.sh <SITE NAME> <WEBDOCS DIRECTORY>
# Example: generate-webdocs.sh "Example Content" "/usr/local/www/ContentCGI/webdocs"

if [ "$1" == "" ] || [ "$2" == "" ]; then
   echo "USAGE: generate-webdocs.sh <SITE NAME> <WEBDOCS DIRECTORY>"
   exit 1
fi

MODELS="${0%generate-webdocs.sh}models"
if [ ! -d "$MODELS" ]; then
   echo "The directory containing the models for the web documents does not exist."
   exit 1
fi

/bin/mkdir -p "$2/articles/media"
if [ ! -d "$2/articles/media" ]; then
   echo "The directory for the web documents could not be created."
   exit 1
fi

/bin/cp "$MODELS/"* "$2/"

# derive index.html
/bin/echo -n "<!--S-->" \
| /bin/cat - "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Résumés<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;/<\!--e-->/d;s/Place a beautiful and descriptive title here!/No articles yet/;/<p>/,/<\!--E-->/d;" \
> "$2/index.html"

# derive imprint.html
/bin/cat "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Imprint<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;s/Place a beautiful and descriptive title here!/Imprint/;s/The first paragraph.*/The first paragraph \.\.\./;" \
> "$2/imprint.html"

# derive privacy.html
/bin/cat "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Privacy and Data Protection<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;s/Place a beautiful and descriptive title here!/Privacy and Data Protection/;s/The first paragraph.*/The first paragraph \.\.\./;" \
> "$2/privacy.html"

# derive disclaimer.html
/bin/cat "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Disclaimer<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;s/Place a beautiful and descriptive title here!/Disclaimer/;s/The first paragraph.*/The first paragraph \.\.\./;" \
> "$2/disclaimer.html"

# derive impressum.html
/bin/cat "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Impressum<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;s/Place a beautiful and descriptive title here!/Impressum/;s/The first paragraph.*/Der erste Absatz \.\.\./;s/Another paragraph.*/Nächster Absatz \.\.\./;" \
> "$2/impressum.html"

# derive datenschutz.html
/bin/cat "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Datenschutzerklärung<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;s/Place a beautiful and descriptive title here!/Datenschutzerklärung/;s/The first paragraph.*/Der erste Absatz \.\.\./;s/Another paragraph.*/Nächster Absatz \.\.\./;" \
> "$2/datenschutz.html"

# derive haftung.html
/bin/cat "$2/model.html" \
| /usr/bin/sed "s/<TITLE>.*<\/TITLE>/<TITLE>Haftungsausschluß<\/TITLE>/;/<BASE href=\"..\/\">/,/.*<LINK/{/<BASE href=\"..\/\">/d;};s/<H1><A href=\".\/\">CONTENT_TITLE<\/A><\/H1>/<H1><A href=\".\/\">$1<\/A><\/H1>/;s/Place a beautiful and descriptive title here!/Haftungsausschluß/;s/The first paragraph.*/Der erste Absatz \.\.\./;s/Another paragraph.*/Nächster Absatz \.\.\./;" \
> "$2/haftung.html"

# the model file is no more needed
rm -f "$2/model.html"

# create toc.html
echo "<!--S--><!DOCTYPE html><HTML><HEAD>" > "$2/toc.html"
echo "   <TITLE>Table of Contents</TITLE>" >> "$2/toc.html"
echo "   <META http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">" >> "$2/toc.html"
echo "   <LINK rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">" >> "$2/toc.html"
echo "</HEAD><BODY class=\"toc\">" >> "$2/toc.html"
echo "   <FORM action=\"_search\" method=\"POST\" target=\"_top\"><INPUT class=\"search\" name=\"search\" type=\"text\" placeholder=\"Search the Content\"></FORM>" >> "$2/toc.html"
echo "   <P>No articles yet</P>" >> "$2/toc.html"
echo "</BODY></HTML>" >> "$2/toc.html"

# link logo.png to apple-touch-icon-precomposed.png
rm -f "$2/apple-touch-icon-precomposed.png"
ln -s "logo.png" "$2/apple-touch-icon-precomposed.png"
