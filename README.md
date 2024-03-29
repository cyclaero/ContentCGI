### [ACTION REQUIRED] Your GitHub account, cyclaero, will soon require 2FA
Here is the deal: https://obsigna.com/articles/1693258424.html

 
## ContentCGI
Extensible FastCGI Daemon for FreeBSD


### Build, Install and Launch on FreeBSD in about 5 minutes:

Login as User root, and install the requisites by the way of the FreeBSD package+ports system:

    pkg install -y apache24
    pkg install -y clone
    pkg install -y subversion
    pkg install -y libobjc2
    pkg install -y utf8proc
    pkg install -y iconv
    pkg install -y poppler-utils
    pkg install -y clone

For image processing we would employ GraphicsMagic. The default options drag-in a lot of unfortunate stuff from the GNU Compiler Collection and from X11. Therefore, add the few really needed dependencies of GraphicsMagic from the FreeBSD package repository, and build+install graphic/GraphicsMagick from the ports with a custom option-set.

    pkg install -y webp
    pkg install -y libwmf-nox11

    cd /usr/ports/graphics/GraphicsMagick
    make config

Disable `Jasper`, `OpenMP`, `X11`  
Enable `SSE`  
<img src="https://obsigna.com/articles/media/1529528376/GM-Options.png">

    make install clean
   

Prepare the installation directory and checkout the sources:

    mkdir -p ~/install

    cd ~/install
    svn checkout https://github.com/cyclaero/ContentCGI.git/trunk ContentCGI
    svn checkout https://github.com/GetmeUK/ContentTools.git/trunk ContentCGI/ContentTools
    svn checkout https://github.com/cyclaero/zettair.git/trunk/devel/src ContentCGI/plugins/search-delegate/zettair-spider

    cd ~/install/ContentCGI

Execute the building and installation script:

    ./bsdinstall.sh install clean
   

Copy the virtual host configuration file into the Apache `Includes` directory. It is wise to name the virtual host config file using the desired domain name:

    cp -p apache-vhost.conf /usr/local/etc/apache24/Includes/your.content.dom.conf

Use the `sed` command  to set the site's title, and to substitute the virtual host dummy domains `example.com` and `content.example.com` to the desired domain names, e.g. `"Your Content"` - `content.dom` - `your.content.dom`:

    sed -i "" -e "s/CONTENT EXAMPLE/Your Content/"         /usr/local/etc/apache24/Includes/your.content.dom.conf
    sed -i "" -e "s/content.example.com/your.content.dom/" /usr/local/etc/apache24/Includes/your.content.dom.conf
    sed -i "" -e "s/example.com/content.dom/"              /usr/local/etc/apache24/Includes/your.content.dom.conf
   

Create the password digest file of the HTTP Digest authentication for editing the content. Inform your real name, because the system will use this name in the signature of the articles:

    htdigest -c /usr/local/etc/apache24/ContentEditors.passwd ContentEditors "Your Real Name"

We may add more users with the same command but __without__ the `-c` flag:

    htdigest /usr/local/etc/apache24/ContentEditors.passwd ContentEditors "Author II Real Name"
   

Use the shell script `generate-webdocs.sh` for populating the site's directory with an initial set of yet empty web documents, derived from the model files of the `content-delegate` plugin:

    plugins/content-delegate/generate-webdocs.sh "Your Content" /usr/local/www/ContentCGI/webdocs
    chown -R www:www /usr/local/www/ContentCGI
    chmod -R o-rwx /usr/local/www/ContentCGI
   

Check the Apache configuration, the output of the following command should be `Syntax OK`:

    httpd -t

Enable Apache and ContentCGI in `/etc/rc.conf` by adding the following lines - make sure the CGI daemon runs as the non-privileged user `www`:

    clear_tmp_enable="YES"
    apache24_enable="YES"
    ContentCGI_flags="-u www:www -w /usr/local/www/ContentCGI/webdocs"
    ContentCGI_enable="YES"

Start Apache and the ContentCGI Daemon:

    service apache24 start
    service ContentCGI start
   

Prepare the working directory for the Zettair search engine:

    mkdir -p /var/db/zettair/your.content.dom
    chown -R www:www /var/db/zettair/your.content.dom
    chmod -R o-rwx /var/db/zettair/your.content.dom

Add to `/etc/crontab` the following lines:

    #
    # call the Zettair spider every minute - it will re-index the articles, if a respective token is present in /var/db/zettair/your.content.dom
    *       *       *       *       *       www     /usr/local/bin/spider /usr/local/www/ContentCGI/webdocs/articles your.content.dom > /dev/null 2>&1
   

Point your browser to your domain and explore the system - `https://obsigna.com/articles/1529528376.html`
<IMG src="https://obsigna.com/articles/media/1529528376/Obsigna's%20Test.png">
