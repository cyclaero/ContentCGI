## ContentCGI
Extensible FastCGI Daemon for FreeBSD

## Building and installation

   git clone https://github.com/cyclaero/ContentCGI.git
   cd ContentCGI
   git submodule update --init --recursive
   cd plugins
   make install clean
   cd content-delegate
   make install clean
   cd ../..
   make install clean
