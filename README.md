## ContentCGI
Extensible FastCGI Daemon for FreeBSD


### Build, Install and Launch on FreeBSD in about 5 minutes:

Login as User root, and install the requisites:

    pkg install apache24
    pkg install clone
    pkg install subversion
    pkg install libobjc2
    pkg install icu


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
    sed -i "" -e "s/example.com/content.dom/"              /usr/local/etc/apache24/Includes/your.content.dom.conf
    sed -i "" -e "s/content.example.com/your.content.dom/" /usr/local/etc/apache24/Includes/your.content.dom.conf


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

    apache24_enable="YES"
    ContentCGI_flags="-u www:www"
    ContentCGI_enable="YES"

Start Apache and the ContentCGI Daemon:

    service apache24 start
    service ContentCGI start


Prepare the working directory for the Zettair search engine:

    mkdir -p /var/db/zettair
    chown -R www:www /var/db/zettair
    chmod -R o-rwx /var/db/zettair

Add to `/etc/crontab` the following lines:

    #
    # call the Zettair spider every minute - it will re-index the articles, if a respective token is present in /var/db/zettair
    *       *       *       *       *       www     /usr/local/bin/spider /usr/local/www/ContentCGI/webdocs/articles > /dev/null 2>&1


Point your browser to your domain and explore the system.
<A href="https://obsigna.com/"><IMG src="https://obsigna.com/articles/media/2018/Obsigna's Test.png"></A>
