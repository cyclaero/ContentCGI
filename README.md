## ContentCGI
Extensible FastCGI Daemon for FreeBSD


### Building and installation on FreeBSD

Login as User root:

Install the requesistes:

    pkg install clone
    pkg install subversion
    pkg install libobjc2
    pkg install icu

Prepare the installation directory and cheout the sources

    mkdir -p ~/install

    cd ~/install
    svn checkout https://github.com/cyclaero/ContentCGI.git/trunk ContentCGI
    svn checkout https://github.com/GetmeUK/ContentTools.git/trunk ContentCGI/ContentTools
    svn checkout https://github.com/cyclaero/zettair.git/trunk/devel/src ContentCGI/plugins/search-delegate/zettair-spider

    cd ~/install/ContentCGI
    
Execute the builing and installation script:

    ./bsdinstall.sh install clean


Copy the virtual host configuration file into the Apache Includes directory it is wise to name the virtual host config file using the desired domain name:

    cp -p apache-vhost.conf /usr/local/etc/apache24/Includes/your.content.dom.conf


Use sed to set the site's title, and substitute the vhost dummy domains 'example.com' and `content.examle.com` to the desired domain names - "Your Content" - content.dom - your.content.dom

    sed -i "" -e 's/"Example Content"/"Your Content"/;'     /usr/local/etc/apache24/Includes/your.content.dom.conf
    sed -i "" -e 's/example.com/content.dom/;'              /usr/local/etc/apache24/Includes/your.content.dom.conf
    sed -i "" -e 's/content.example.com/your.content.dom/;' /usr/local/etc/apache24/Includes/your.content.dom.conf

Create the password digest file of the HTTP Digest authentication for editing the content inform your real name, because the system will use this name in the signature of the articles

    htdigest -c /usr/local/etc/apache24/ContentEditors.passwd ContentEditors "Your Real Name"

We may add more users with the same command but __without__ the `-c` flag

    htdigest /usr/local/etc/apache24/ContentEditors.passwd ContentEditors "Author II Real Name"


Use the shell-script `generate-webdocs.sh` for populating the site's directory with an initial set of yet empty web documents, derived from the model files of the `content-delegate` plugin:

    plugins/content-delegate/generate-webdocs.sh "Your Content" /usr/local/www/ContentCGI/webdocs
    chown -R www:www /usr/local/www/ContentCGI
    chmod -R o-rwx /usr/local/www/ContentCGI


Check the Apache configuration, the output of the following command should be `Syntax OK`:

    httpd -t

Start Apache

    service apache24 [re]start


Enable ContentCGI in `/etc/rc.conf` by adding the following lines - make sure it runs as the non-privileged user `www`:

    ContentCGI_flags="-u www:www"
    ContentCGI_enable="YES"

Start the ContentCGI Daemon

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
