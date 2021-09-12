//  main.c
//  ContentCGI
//
//  Created by Dr. Rolf Jansen on 2018-05-08.
//  Copyright © 2018-2021 Dr. Rolf Jansen. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.


#include <stdlib.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <dirent.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#include <syslog.h>
#include <signal.h>
#include <pwd.h>
#include <grp.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#include <openssl/ssl.h>
#include <openssl/err.h>


// ContentCGI facilities
#include "utils.h"
#include "interim.h"
#include "connection.h"
#include "firstresponder.h"

#include "plugins/exports.h"


#define DAEMON_NAME    "ContentCGI"

const char *pidfname = "/var/run/"DAEMON_NAME".pid";
const char *usocket  = "/tmp/"DAEMON_NAME".sock";


#pragma mark ••• Delegate Plugins •••

// defined in firstresponder.c
extern Plugins *gPlugins;

void cached_response_deallocate(void **p, int32_t offset, boolean cleanout)
{
   Response *response = *p; *p = NULL;
   deallocate_batch(cleanout, VPR(response->content), VPR(response), NULL);
}

static void loadPlugins(const char *dir, size_t len)
{
   static const char *plugd  = NULL;
   static size_t      plugdl = 0;

   if (dir)
      plugd = dir, plugdl = len;

   if (plugd)
   {
      struct stat st;
      if (stat(plugd, &st) == no_error && S_ISDIR(st.st_mode))
      {
         DIR           *dp;
         struct dirent *ep, bp;
         if (dp = opendir(plugd))
         {
            Plugins *prev = NULL, *plugin = gPlugins;

            while (readdir_r(dp, &bp, &ep) == no_error && ep)
               if (ep->d_name[0] != '.' && ep->d_type == DT_DIR)
               {
                  int  subdpl = (int)plugdl+1+ep->d_namlen;
                  char subdp[OSP(subdpl+1)];
                  strmlcat(subdp, subdpl+1, NULL, plugd, plugdl, "/", 1, ep->d_name, ep->d_namlen, NULL);
                  int  filepl = subdpl+1+ep->d_namlen;
                  char filep[OSP(filepl+6)];
                  strmlcat(filep, filepl+6, NULL, subdp, subdpl, "/", 1, ep->d_name, ep->d_namlen, ".so", 3, NULL);
                  if (stat(filep, &st) == no_error && S_ISREG(st.st_mode))
                  {
                     void *pluglib = NULL;
                     if (pluglib = dlopen(filep, RTLD_NOW|RTLD_LOCAL))
                     {
                        if (!gPlugins)
                           gPlugins = plugin = allocate(sizeof(Plugins), vector_align, true);
                        else
                           prev = plugin, plugin = plugin->next = allocate(sizeof(Plugins), vector_align, true);

                        if ((plugin->initialize = dlsym(pluglib, "initialize"))
                         && (plugin->respond    = dlsym(pluglib, "respond"))
                         && (plugin->freeback   = dlsym(pluglib, "freeback"))
                         && (plugin->release    = dlsym(pluglib, "release")))
                        {
                           plugin->cache.path = strcpy(allocate(subdpl+1, default_align, false), subdp);

                           // read in and cache additional source files used by the respective plugin
                           FILE *srcfile;

                           // HTML
                           cpy5(filep+filepl+1, "html");
                           if (stat(filep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(filep, "r")))
                           {
                              plugin->cache.html.content = allocate((ssize_t)st.st_size+1, default_align, false);
                              if (plugin->cache.html.content)
                                 if (fread(plugin->cache.html.content, (size_t)st.st_size, 1, srcfile) == 1)
                                 {
                                    plugin->cache.html.content[plugin->cache.html.contlen = st.st_size] = '\0';
                                    plugin->cache.html.contdat = st.st_mtimespec.tv_sec;
                                    httpETag(plugin->cache.html.conttag , &st, false);
                                    plugin->cache.html.conttyp = "text/html; charset=utf-8";
                                 }
                                 else
                                    deallocate(VPR(plugin->cache.html.content), false);
                              fclose(srcfile);
                           }

                           // CSS
                           cpy4(filep+filepl+1, "css");
                           if (stat(filep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(filep, "r")))
                           {
                              plugin->cache.css.content = allocate((ssize_t)st.st_size+1, default_align, false);
                              if (plugin->cache.css.content)
                                 if (fread(plugin->cache.css.content, (size_t)st.st_size, 1, srcfile) == 1)
                                 {
                                    plugin->cache.css.content[plugin->cache.css.contlen = st.st_size] = '\0';
                                    plugin->cache.css.contdat = st.st_mtimespec.tv_sec;
                                    httpETag(plugin->cache.css.conttag , &st, false);
                                    plugin->cache.css.conttyp = "text/css; charset=utf-8";
                                 }
                                 else
                                    deallocate(VPR(plugin->cache.css.content), false);
                              fclose(srcfile);
                           }

                           // JS
                           cpy4(filep+filepl, ".js");
                           if (stat(filep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(filep, "r")))
                           {
                              plugin->cache.js.content = allocate((ssize_t)st.st_size+1, default_align, false);
                              if (plugin->cache.js.content)
                                 if (fread(plugin->cache.js.content, (size_t)st.st_size, 1, srcfile) == 1)
                                 {
                                    plugin->cache.js.content[plugin->cache.js.contlen = st.st_size] = '\0';
                                    plugin->cache.js.contdat = st.st_mtimespec.tv_sec;
                                    httpETag(plugin->cache.js.conttag , &st, false);
                                    plugin->cache.js.conttyp = "application/x-javascript";
                                 }
                                 else
                                    deallocate(VPR(plugin->cache.js.content), false);
                              fclose(srcfile);
                           }

                           // PNG
                           cpy4(filep+filepl+1, "png");
                           if (stat(filep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(filep, "r")))
                           {
                              plugin->cache.png.content = allocate((ssize_t)st.st_size+1, default_align, false);
                              if (plugin->cache.png.content)
                                 if (fread(plugin->cache.png.content, (size_t)st.st_size, 1, srcfile) == 1)
                                 {
                                    plugin->cache.png.content[plugin->cache.png.contlen = st.st_size] = '\0';
                                    plugin->cache.png.contdat = st.st_mtimespec.tv_sec;
                                    httpETag(plugin->cache.png.conttag , &st, false);
                                    plugin->cache.png.conttyp = "image/png";
                                 }
                                 else
                                    deallocate(VPR(plugin->cache.png.content), false);
                              fclose(srcfile);
                           }

                           // ICO
                           cpy4(filep+filepl+1, "ico");
                           if (stat(filep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(filep, "r")))
                           {
                              plugin->cache.ico.content = allocate((ssize_t)st.st_size+1, default_align, false);
                              if (plugin->cache.ico.content)
                                 if (fread(plugin->cache.ico.content, (size_t)st.st_size, 1, srcfile) == 1)
                                 {
                                    plugin->cache.ico.content[plugin->cache.ico.contlen = st.st_size] = '\0';
                                    plugin->cache.ico.contdat = st.st_mtimespec.tv_sec;
                                    httpETag(plugin->cache.ico.conttag , &st, false);
                                    plugin->cache.ico.conttyp = "image/x-icon";
                                 }
                                 else
                                    deallocate(VPR(plugin->cache.ico.content), false);
                              fclose(srcfile);
                           }

                           // load the files of a possible models directory into the plugins cache
                           char *modeldir = strcpy(alloca(OSP(subdpl+7+1)), subdp);
                           cpy8(modeldir+subdpl, "/models");
                           if (stat(modeldir, &st) == no_error && S_ISDIR(st.st_mode))
                           {
                              DIR           *idp;
                              struct dirent *iep, ibp;
                              if (idp = opendir(modeldir))
                              {
                                 Value value = {{.p = NULL}, dynamic*Data, 0, 0, cached_response_deallocate};

                                 while (readdir_r(idp, &ibp, &iep) == no_error && iep)
                                    if (iep->d_name[0] != '.' && (iep->d_type == DT_REG || iep->d_type == DT_LNK))
                                    {
                                       int  modelpl = subdpl+7+1+iep->d_namlen;
                                       char modelp[OSP(modelpl+1)];
                                       strmlcat(modelp, modelpl+1, NULL, modeldir, subdpl+7, "/", 1, iep->d_name, iep->d_namlen, NULL);
                                       if (stat(modelp, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(modelp, "r")))
                                       {
                                          Response *response;
                                          if (response = allocate(sizeof(Response), vector_align, true))
                                             if (response->content = allocate((ssize_t)st.st_size+1, default_align, false))
                                                if (fread(response->content, (size_t)st.st_size, 1, srcfile) == 1)
                                                {
                                                   response->content[response->contlen = st.st_size] = '\0';
                                                   response->contdat = st.st_mtimespec.tv_sec;
                                                   httpETag(response->conttag , &st, false);
                                                   response->conttyp = (char *)extensionToType(iep->d_name, iep->d_namlen);
                                                   value.p = response;

                                                   if (!plugin->cache.models)
                                                      plugin->cache.models = createTable(64);
                                                   storeName(plugin->cache.models, iep->d_name, iep->d_namlen, &value);
                                                }
                                                else
                                                   deallocate_batch(false, VPR(response->content), VPR(response), NULL);
                                             else
                                                deallocate(VPR(response), false);

                                          fclose(srcfile);
                                       }
                                    }

                                 closedir(idp);
                              }
                           }

                           // load the files of a possible images directory into the plugins cache
                           char *imagedir = strcpy(alloca(OSP(subdpl+7+1)), subdp);
                           cpy8(imagedir+subdpl, "/images");
                           if (stat(imagedir, &st) == no_error && S_ISDIR(st.st_mode))
                           {
                              DIR           *idp;
                              struct dirent *iep, ibp;
                              if (idp = opendir(imagedir))
                              {
                                 Value value = {{.p = NULL}, dynamic*Data, 0, 0, cached_response_deallocate};

                                 while (readdir_r(idp, &ibp, &iep) == no_error && iep)
                                    if (iep->d_name[0] != '.' && (iep->d_type == DT_REG || iep->d_type == DT_LNK))
                                    {
                                       int  imagepl = subdpl+7+1+iep->d_namlen;
                                       char imagep[OSP(imagepl+1)];
                                       strmlcat(imagep, imagepl+1, NULL, imagedir, subdpl+7, "/", 1, iep->d_name, iep->d_namlen, NULL);
                                       if (stat(imagep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size && (srcfile = fopen(imagep, "r")))
                                       {
                                          Response *response;
                                          if (response = allocate(sizeof(Response), vector_align, true))
                                             if (response->content = allocate((ssize_t)st.st_size+1, default_align, false))
                                                if (fread(response->content, (size_t)st.st_size, 1, srcfile) == 1)
                                                {
                                                   response->content[response->contlen = st.st_size] = '\0';
                                                   response->contdat = st.st_mtimespec.tv_sec;
                                                   httpETag(response->conttag , &st, false);
                                                   response->conttyp = (char *)extensionToType(iep->d_name, iep->d_namlen);
                                                   value.p = response;

                                                   if (!plugin->cache.images)
                                                      plugin->cache.images = createTable(64);
                                                   storeName(plugin->cache.images, iep->d_name, iep->d_namlen, &value);
                                                }
                                                else
                                                   deallocate_batch(false, VPR(response->content), VPR(response), NULL);
                                             else
                                                deallocate(VPR(response), false);

                                          fclose(srcfile);
                                       }
                                    }

                                 closedir(idp);
                              }
                           }

                           if (plugin->initialize(&plugin->cache))
                              plugin->pluglib = pluglib;

                           else
                           {
                              releaseTable(plugin->cache.images);
                              releaseTable(plugin->cache.models);
                              deallocate_batch(false, VPR(plugin->cache.ico.content),
                                                      VPR(plugin->cache.png.content),
                                                      VPR(plugin->cache.js.content),
                                                      VPR(plugin->cache.css.content),
                                                      VPR(plugin->cache.html.content),
                                                      VPR(plugin->cache.path),
                                                      VPR(plugin), NULL);
                              dlclose(pluglib);

                              if (prev)
                                 plugin = prev;
                              else
                                 gPlugins = NULL;
                           }
                        }
                        else
                           dlclose(pluglib);
                     }
                     else
                        syslog(LOG_ERR, "%s", dlerror());
                  }
               }

            closedir(dp);
         }
      }
   }
}

static void releasePlugins(void)
{
   Plugins *plugin, *next;

   for (plugin = gPlugins; plugin; plugin = next)
   {
      plugin->release();
      releaseTable(plugin->cache.images);
      releaseTable(plugin->cache.models);
      deallocate_batch(false, VPR(plugin->cache.ico.content),
                              VPR(plugin->cache.png.content),
                              VPR(plugin->cache.js.content),
                              VPR(plugin->cache.css.content),
                              VPR(plugin->cache.html.content),
                              VPR(plugin->cache.path), NULL);

      if (dlclose(plugin->pluglib) == -1)
         syslog(LOG_ERR, "Dynamic library was not unloaded: %s.", dlerror());

      next = plugin->next;
      deallocate(VPR(plugin), false);
   }

   gPlugins = NULL;
}


#pragma mark ••• Daemon Setup & Usage •••

static void signals(int sig)
{
   switch (sig)
   {
      default:
         syslog(LOG_ERR, "Unhandled signal (%d) %s.", sig, strsignal(sig));
         break;

      case SIGURG:
         releasePlugins();
         loadPlugins(NULL, 0);
         syslog(LOG_INFO, "Received SIGURG signal --> plugins reloaded.");
         break;

      case SIGHUP:
         syslog(LOG_ERR, "Received SIGHUP signal.");
         goto finish;

      case SIGINT:
         syslog(LOG_ERR, "Received SIGINT signal.");
         goto finish;

      case SIGQUIT:
         syslog(LOG_ERR, "Received SIGQUIT signal.");
         goto finish;

      case SIGTERM:
         syslog(LOG_ERR, "Received SIGTERM signal.");

      finish:
         unlink(pidfname);
         exit(0);
   }
}


typedef enum
{
   noDaemon,
   launchdDaemon,
   discreteDaemon
} DaemonKind;


void daemonize(DaemonKind kind)
{
   switch (kind)
   {
      case noDaemon:
         signal(SIGURG, signals);
         openlog(DAEMON_NAME, LOG_NDELAY | LOG_PID | LOG_CONS | LOG_PERROR, LOG_USER);
         break;

      case launchdDaemon:
         signal(SIGURG,  signals);
         signal(SIGTERM, signals);
         openlog(DAEMON_NAME, LOG_NDELAY | LOG_PID, LOG_USER);
         break;

      case discreteDaemon:
      {
         // fork off the parent process
         pid_t pid = fork();

         if (pid > 0)            // got a good PID, so exit the parent process.
            exit(EXIT_SUCCESS);

         else if (pid < 0)
         {
            syslog(LOG_ERR, "Could not fork of a daemon, error: %d.\n", errno);
            exit(EXIT_FAILURE);
         }

         // The child process continues here, first close all open descriptors
         for (int i = getdtablesize(); i >= 0; --i)
            close(i);

         // re-open stdin, stdout, stderr connected to /dev/null
         int inouterr = open("/dev/null", O_RDWR);     // stdin
         dup(inouterr);                                // stdout
         dup(inouterr);                                // stderr

      #ifdef __FREEBSD__
         // Change the file mode mask, 027 = complement of 750 - on FreeBSD the web documents are in the www group, no need to give read access to others
         umask(027);
      #else
         // Change the file mode mask, 022 = complement of 755 - on the Mac the web documents are not in the _www group, so Apache needs read access by the way of others
         umask(022);
      #endif

         pid_t sid = setsid();
         if (sid < 0)
         {
            syslog(LOG_ERR, "The daemon could not create a new session - error: %d.\n", errno);
            exit(EXIT_FAILURE);
         }

         // Check and write our pid lock file and mutually exclude other instances from running
         int pidfile = open(pidfname, O_RDWR|O_CREAT, 0640);
         if (pidfile < 0)
         {
            syslog(LOG_ERR, "The daemon could not open its pid file - error: %d.\n", errno);
            exit(EXIT_FAILURE);
         }

         if (lockf(pidfile, F_TLOCK, 0) < 0)
         {
            syslog(LOG_ERR, "The daemon could not lock its pid file - %d\n", errno);
            exit(EXIT_FAILURE);
         }

         // only first instance continues beyound this
         intStr is;
         int il = int2str(is, getpid(), intLen, 0 );
         write(pidfile, is, il);    // record pid to our pid file

         signal(SIGURG,  signals);
         signal(SIGHUP,  signals);
         signal(SIGINT,  signals);
         signal(SIGQUIT, signals);
         signal(SIGTERM, signals);
         signal(SIGCHLD, SIG_IGN);  // ignore child
         signal(SIGTSTP, SIG_IGN);  // ignore tty signals
         signal(SIGTTOU, SIG_IGN);
         signal(SIGTTIN, SIG_IGN);

         openlog(DAEMON_NAME, LOG_NDELAY | LOG_PID, LOG_USER);
         break;
      }
   }
}


void usage(const char *executable)
{
   const char *r = executable + strvlen(executable);
   while (--r >= executable && r && *r != '/'); r++;
   printf("\nusage: %s [-f] [-n] [-l local port] [-a local IPv4] [-b local IPv6] [-s secure port] [-c cert dir] [-r plugins] [-w web root] [-u uid:gid] [-p pid file] [-u unix domain socket] [-h|?]\n", r);
   printf(" -f             foreground mode, don't fork off as a daemon.\n");
   printf(" -n             no console, don't fork off as a daemon - started/managed by launchd.\n");
   printf(" -l local port  listen on the non-TLS local host/net port number, port 0 means don't listen [default: 4000].\n");
   printf(" -a local IPv4  bind non-TLS "DAEMON_NAME" to the given IPv4 address [default: 127.0.0.1].\n");
   printf(" -b local IPv6  bind non-TLS "DAEMON_NAME" to the given IPv4 address [default: ::1].\n");
   printf(" -s secure port listen on the TLS secure remote port number, port 0 means don't listen [default: 5000].\n");
   printf(" -4 IPv4        bind TLS "DAEMON_NAME" to the given IPv4 address [default: 0.0.0.0].\n");
   printf(" -6 IPv6        bind TLS "DAEMON_NAME" to the given IPv6 address [default: ::].\n");
   printf(" -c cert dir    the path to the directory holding the certificate chain [default: ~/certdir].\n");
   printf(" -r plugins     the path to the async responder plugins directory [default: ~/plugins/"DAEMON_NAME"].\n");
   printf(" -w web root    the path to the web root directory [default: ~/webroot].\n");
   printf(" -u uid:gid     switch to another user:group before launching the child.\n");
   printf(" -p pid file    the path to the pid file [default: /var/run/"DAEMON_NAME".pid]\n");
   printf(" -d unix socket the path to the unix domain socket on which "DAEMON_NAME" is listening on [default: /tmp/"DAEMON_NAME".sock].\n");
   printf(" ?|-h           shows these usage instructions.\n\n");
}


boolean gShutdownFlag = false;

int gListenSocket_ud = 0;
int gListenSocket_v4 = 0;
int gListenSocket_v6 = 0;
int gListenSSockL_v4 = 0;
int gListenSSockL_v6 = 0;


#pragma mark ••• main •••

SSL_CTX *gCTX = NULL;

pthread_t      thread;
pthread_attr_t detach;


// Device and file system informations
int    *gSourceFSType;
boolean gSourceRdOnly;
dev_t   gSourceDev;

int    *gDestinFSType;
dev_t   gDestinDev;


void *socketLoop(void *listenSocket)
{
   long double mt, lastfail = microtime();
   const int optval = 1;
   int rc, socket;

   while (!gShutdownFlag)
   {
      if ((socket = accept(*(int *)listenSocket, NULL, NULL)) < 0)
      {
         if (gShutdownFlag)
            exit(0);
         syslog(LOG_ERR, "Error calling accept(): %d.", rc = errno);

         mt = microtime();
         if (rc != ECONNABORTED && mt - lastfail < 0.01)
            exit(EXIT_FAILURE);           // it is fatal if subsequent calls to accept() fail rapidly (< 10 ms) in a row
         else
         {
            lastfail = mt;
            continue;                     // try again
         }
      }

      ConnExec *connex = allocate(sizeof(ConnExec), default_align, false);
      if (!connex)
      {
         syslog(LOG_ERR, "Insufficient memory for establishing a client connection.");
         shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating insufficient memory for any operations
         close(socket);
         exit(EXIT_FAILURE);
      }
      *connex = (ConnExec){{socket, 0, NULL}, 0, createTable(256), NULL, NULL, &socketRecv, &socketARcv, &socketSend, &socketJSnd, &socketShut};

      if (!connex->serverTable)
      {
         syslog(LOG_ERR, "Insufficient memory retrieving the connection meta data of the HTTP server.");
         shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating insufficient memory for any operations
         close(socket);
         deallocate(VPR(connex), false);
         exit(EXIT_FAILURE);
      }

      setsockopt(connex->conn.sock, SOL_SOCKET, SO_NOSIGPIPE, &optval, sizeof(int));
      setsockopt(connex->conn.sock, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(int));
      if (rc = pthread_create(&thread, &detach, firstresponder, connex))
      {
         syslog(LOG_ERR, "Cannot create a new thread for responding to a client connection: %d.", rc);
         shutdown(socket, SHUT_RDWR);
         close(socket);
         connexRelease(&connex);
         exit(EXIT_FAILURE);
      }
   }

   return NULL;
}


void *ssocklLoop(void *listenSSockL)
{
   long double mt, lastfail = microtime();
   const int optval = 1;
   int rc, socket;

   while (!gShutdownFlag)
   {
      if ((socket = accept(*(int *)listenSSockL, NULL, NULL)) < 0)
      {
         if (gShutdownFlag)
            exit(0);
         syslog(LOG_ERR, "Error calling accept(): %d.", rc = errno);

         mt = microtime();
         if (rc != ECONNABORTED && mt - lastfail < 0.01)
            exit(EXIT_FAILURE);           // it is fatal if subsequent calls to accept() fail rapidly (< 10 ms) in a row
         else
         {
            lastfail = mt;
            continue;                     // try again
         }
      }

      ConnExec *connex = allocate(sizeof(ConnExec), default_align, false);
      if (!connex)
      {
         syslog(LOG_ERR, "Insufficient memory for establishing a client connection.");
         shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating insufficient memory for any operations
         close(socket);
         exit(EXIT_FAILURE);
      }
      *connex = (ConnExec){{socket, 0, NULL}, 0, createTable(256), NULL, NULL, &ssocklRecv, &ssocklARcv, &ssocklSend, &ssocklJSnd, &ssocklShut};

      if (!connex->serverTable)
      {
         syslog(LOG_ERR, "Insufficient memory retrieving the connection meta data of the HTTP server.");
         shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating insufficient memory for any operations
         close(socket);
         deallocate(VPR(connex), false);
         exit(EXIT_FAILURE);
      }

      setsockopt(connex->conn.sock, SOL_SOCKET, SO_NOSIGPIPE, &optval, sizeof(int));
      setsockopt(connex->conn.sock, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(int));
      if ((connex->conn.ssl = SSL_new(gCTX)) == NULL || SSL_set_fd(connex->conn.ssl, connex->conn.sock) == 0)
      {
         syslog(LOG_ERR, "Cannot create/assign the TLS structure for a client connection.");
         shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating problems with the TLS setup
         close(socket);
         connexRelease(&connex);
         exit(EXIT_FAILURE);
      }

      if ((rc = SSL_accept(connex->conn.ssl)) <= 0)
      {
         syslog(LOG_ERR, "Could not establish a secure connection because the TLS handshake failed: %d.", SSL_get_error(connex->conn.ssl, rc));
         shutdown(socket, SHUT_RDWR);     // this is not a fatal error for the server, so simply cleanup and continue accepting new connections.
         close(socket);
         SSL_free(connex->conn.ssl);
         connexRelease(&connex);
         continue;
      }

      if (rc = pthread_create(&thread, &detach, firstresponder, connex))
      {
         syslog(LOG_ERR, "Cannot create thread for responding to a client connection: %d.", rc);
         shutdown(socket, SHUT_RDWR);
         close(socket);
         SSL_free(connex->conn.ssl);
         connexRelease(&connex);
         exit(EXIT_FAILURE);
      }
   }

   return NULL;
}


#define thread_stack_size 2097152

int     gURandom;

boolean SSL_thread_setup(void);
void    SSL_thread_cleanup(void);
void    SSL_CTX_cleanup(void);
void    urandom_close(void);
void    usocket_delete(void);


int main(int argc, char *const argv[])
{
   int             ch;
   int             rc;
   const char     *command   = argv[0];

   DaemonKind      dKind     = discreteDaemon;
   int64_t         uid       = -1;   // do not set the uid
   int64_t         gid       = -1;   // do not set the gid

   const char     *certdir   = "~/certdir";
   const char     *plugdir   = "~/plugins/"DAEMON_NAME;
   const char     *webroot   = "~/webroot";

   // sockets setup
   const int       optval    = 1;
   ushort          loc_port  = 4000;
   struct in_addr  loc_addr4 = {htonl(INADDR_LOOPBACK)};
   struct in6_addr loc_addr6 = IN6ADDR_LOOPBACK_INIT;
   ushort          tls_port  = 5000;
   struct in_addr  tls_addr4 = {htonl(INADDR_ANY)};
   struct in6_addr tls_addr6 = IN6ADDR_ANY_INIT;

   struct sockaddr_un unixDomainSocket = {};
   unixDomainSocket.sun_family  = AF_LOCAL;

   struct sockaddr_in serverAddress_v4 = {};
   serverAddress_v4.sin_family  = AF_INET;

   struct sockaddr_in6 serverAddress_v6 = {};
   serverAddress_v6.sin6_family = AF_INET6;

   while ((ch = getopt(argc, argv, "fnl:a:b:s:4:6:c:r:w:u:p:d:h")) != -1)
   {
      switch (ch)
      {
         case 'f':
            dKind = noDaemon;
            break;

         case 'n':
            dKind = launchdDaemon;
            break;

         case 'l':
            loc_port = (ushort)strtol(optarg, NULL, 10);
            break;

         case 'a':
            if ((rc = inet_pton(AF_INET, optarg, &loc_addr4)) != 1)
            {
               if (rc == -1)
                  syslog(LOG_ERR, "System error in parsing local IPv4 address: %d.", errno);
               else
                  syslog(LOG_ERR, "Invalid local IPv4 address given.");
               exit(EXIT_FAILURE);
            }
            break;

         case 'b':
            if ((rc = inet_pton(AF_INET6, optarg, &loc_addr6)) != 1)
            {
               if (rc == -1)
                  syslog(LOG_ERR, "System error in parsing local IPv6 address: %d.", errno);
               else
                  syslog(LOG_ERR, "Invalid local IPv6 address given.");
               exit(EXIT_FAILURE);
            }
            break;

         case 's':
            tls_port = (ushort)strtol(optarg, NULL, 10);
            break;

         case '4':
            if ((rc = inet_pton(AF_INET, optarg, &tls_addr4)) != 1)
            {
               if (rc == -1)
                  syslog(LOG_ERR, "System error in parsing TLS IPv4 address: %d.", errno);
               else
                  syslog(LOG_ERR, "Invalid TLS IPv4 address given.");
               exit(EXIT_FAILURE);
            }
            break;

         case '6':
            if ((rc = inet_pton(AF_INET6, optarg, &tls_addr6)) != 1)
            {
               if (rc == -1)
                  syslog(LOG_ERR, "System error in parsing TLS IPv6 address: %d.", errno);
               else
                  syslog(LOG_ERR, "Invalid TLS IPv6 address given.");
               exit(EXIT_FAILURE);
            }
            break;

         case 'c':
            certdir = optarg;
            break;

         case 'r':
            plugdir = optarg;
            break;

         case 'w':
            webroot = optarg;
            break;

         case 'u':
            if (optarg && !cmp2(optarg, "-"))
            {
               int     sl = strvlen(optarg);
               char   *p, *q;
               int64_t id;
               if (optarg[0] != '-' || optarg[1] != ':')
               {
                  struct passwd *pwd;

                  int fl = collen(optarg);
                  *(q = optarg + fl) = '\0';

                  if ((id = strtol(optarg, &p, 10)) && p == q)
                     uid = (uid_t)id;

                  else if (pwd = getpwnam(optarg))
                  {
                     uid = pwd->pw_uid;
                     gid = pwd->pw_gid;
                     p = q;
                  }

                  else
                  {
                     syslog(LOG_ERR, "Invalid user ID '%s'\n", optarg);
                     exit(EXIT_FAILURE);
                  }

                  if (fl != sl)
                     p += 1;
                  else
                     p = NULL;
               }
               else
                  p = &optarg[1];

               if (p && !cmp2(optarg, "-"))
               {
                  struct group *grp;

                  if ((id = strtol(p, &q, 10)) && q == optarg+sl)
                     gid = id;

                  else if (grp = getgrnam(p))
                     gid = grp->gr_gid;

                  else
                  {
                     syslog(LOG_ERR, "Invalid group ID '%s'\n", p);
                     exit(EXIT_FAILURE);
                  }
               }
            }
            break;

         case 'p':
            pidfname = optarg;
            break;

         case 'd':
            usocket = optarg;
            break;

         case 'h':
         default:
            usage(command);
            exit(0);
            break;
      }
   }
   argc -= optind;
   argv += optind;

   if (argc && argv[0][0] == '?' && argv[0][1] == '\0')
   {
      usage(command);
      exit(0);
   }

   daemonize(dKind);

   size_t  homelen       = 0;
   char   *userhome      = NULL;
   boolean expandPlugDir = cmp2((void *)plugdir, "~/");
   boolean expandWebRoot = cmp2((void *)webroot, "~/");
   boolean expandUSocket = cmp2((void *)usocket, "~/");
   boolean expandCertDir = cmp2((void *)certdir, "~/");
   if (expandPlugDir || expandWebRoot || expandUSocket || expandCertDir)
      homelen = strvlen(userhome = getpwuid(getuid())->pw_dir);

#pragma mark ••• main() -- Plugins Loader •••
   size_t plugdir_len = strvlen(plugdir);
   if (expandPlugDir)
      plugdir = strcat(strcpy(allocate((plugdir_len = homelen + plugdir_len-1)+1, default_align, false), userhome), plugdir+1);
   loadPlugins(plugdir, plugdir_len);

#pragma mark ••• main() -- web root •••
   if (expandWebRoot)
      webroot = strcat(strcpy(alloca(OSP(homelen + strvlen(webroot))), userhome), webroot+1);

   if ((rc = chdir(webroot)) == no_error)
   {
      struct statfs stfs;
      statfs(webroot, &stfs);
      gSourceFSType = gDestinFSType = (int *)stfs.f_fstypename;
      gSourceRdOnly = stfs.f_flags & MNT_RDONLY;

      struct stat st;
      gSourceDev = gDestinDev = (stat(webroot, &st) == no_error) ? st.st_dev : -1;

      pthread_attr_init(&detach);
      pthread_attr_setstacksize(&detach, thread_stack_size);
      pthread_attr_setdetachstate(&detach, PTHREAD_CREATE_DETACHED);

      if ((gURandom = open("/dev/urandom", O_RDONLY)) == -1)
      {
         syslog(LOG_ERR, "Cannot open /dev/urandom: %d.", errno);
         exit(EXIT_FAILURE);
      }
      else
         atexit(urandom_close);

   #pragma mark ••• main() -- Unix Domain Socket setup •••
      if (expandUSocket)
         usocket = strcat(strcpy(alloca(OSP(homelen + strvlen(usocket))), userhome), usocket+1);
      unlink(usocket);

      if ((gListenSocket_ud = socket(AF_LOCAL, SOCK_STREAM, 0)) < 0)
      {
         syslog(LOG_ERR, "Error creating the Unix domain socket.");
         exit(EXIT_FAILURE);
      }

      strmlcpy(unixDomainSocket.sun_path, usocket, sizeof(unixDomainSocket.sun_path), NULL);
      if (bind(gListenSocket_ud, (struct sockaddr *)&unixDomainSocket, sizeof(unixDomainSocket)) < 0)
      {
         syslog(LOG_ERR, "Error calling bind() on the Unix domain socket: %d.", errno);
         exit(EXIT_FAILURE);
      }

      if (chmod(unixDomainSocket.sun_path, 0666) < 0)  // set read/write access for everybody to the just created unix domain socket
      {
         syslog(LOG_ERR, "The access rigths of the Unix domain socket could no be set: %d.", errno);
         exit(EXIT_FAILURE);
      }

      if (listen(gListenSocket_ud, 5) < 0)
      {
         syslog(LOG_ERR, "Error calling listen() on the Unix domain socket.");
         exit(EXIT_FAILURE);
      }

      atexit(usocket_delete);

      if (loc_port != 0)
      {
      #pragma mark ••• main() -- IPv4 local address space non-TLS setup •••
         if ((gListenSocket_v4 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
         {
            syslog(LOG_ERR, "Error creating the non-TLS IPv4 listening socket.");
            exit(EXIT_FAILURE);
         }

         serverAddress_v4.sin_addr = loc_addr4;
         serverAddress_v4.sin_port = htons(loc_port);
         if (setsockopt(gListenSocket_v4, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int)) < 0 ||
             setsockopt(gListenSocket_v4, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(int)) < 0 ||
             bind(gListenSocket_v4, (struct sockaddr *)&serverAddress_v4, sizeof(serverAddress_v4)) < 0)
         {
            syslog(LOG_ERR, "Error calling bind() on the non-TLS IPv4 socket: %d.", errno);
            exit(EXIT_FAILURE);
         }

         if (listen(gListenSocket_v4, 5) < 0)
         {
            syslog(LOG_ERR, "Error calling listen() on the non-TLS IPv4 socket.");
            exit(EXIT_FAILURE);
         }

         if (rc = pthread_create(&thread, &detach, socketLoop, &gListenSocket_v4))
         {
            syslog(LOG_ERR, "Cannot create thread for responding to local IPv4 client connections: %d.", rc);
            exit(EXIT_FAILURE);
         }

      #pragma mark ••• main() -- IPv6 local address space non-TLS setup •••
         if ((gListenSocket_v6 = socket(AF_INET6, SOCK_STREAM, 0)) < 0)
         {
            syslog(LOG_ERR, "Error creating the non-TLS IPv6 listening socket.");
            exit(EXIT_FAILURE);
         }

         serverAddress_v6.sin6_addr   = loc_addr6;
         serverAddress_v6.sin6_port   = htons(loc_port);
         if (setsockopt(gListenSocket_v6, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int)) < 0 ||
             setsockopt(gListenSocket_v6, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(int)) < 0 ||
             bind(gListenSocket_v6, (struct sockaddr *)&serverAddress_v6, sizeof(serverAddress_v6)) < 0)
         {
            syslog(LOG_ERR, "Error calling bind() on the non-TLS IPv6 socket: %d.", errno);
            exit(EXIT_FAILURE);
         }

         if (listen(gListenSocket_v6, 5) < 0)
         {
            syslog(LOG_ERR, "Error calling listen() on the non-TLS IPv4 socket.");
            exit(EXIT_FAILURE);
         }

         if (rc = pthread_create(&thread, &detach, socketLoop, &gListenSocket_v6))
         {
            syslog(LOG_ERR, "Cannot create thread for responding to local IPv6 client connections: %d.", rc);
            exit(EXIT_FAILURE);
         }
      }

      if (tls_port != 0)
      {
      #pragma mark ••• main() -- TLS setup •••
         size_t certdir_len = strvlen(certdir);
         if (expandCertDir)
            certdir = strcat(strcpy(alloca(OSP((certdir_len = homelen + certdir_len-1)+1)), userhome), certdir+1);

         if (stat(certdir, &st) == no_error)
         {
            char *certchain = strcat(strcpy(alloca(OSP(certdir_len+11)), certdir), "/chain.crt");
            char *chainpkey = strcat(strcpy(alloca(OSP(certdir_len+11)), certdir), "/chain.key");
            char *dh1024pem = strcat(strcpy(alloca(OSP(certdir_len+12)), certdir), "/dh1024.pem");
            char *dh2048pem = strcat(strcpy(alloca(OSP(certdir_len+12)), certdir), "/dh2048.pem");

            SSL_library_init();
            SSL_load_error_strings();
            if (SSL_thread_setup())
            {
               atexit(SSL_thread_cleanup);

               DH *dhparam = NULL;
               FILE *dhfile;
               if ((dhfile = fopen(dh2048pem, "r"))
                || (dhfile = fopen(dh1024pem, "r")))
               {
                  dhparam = PEM_read_DHparams(dhfile, NULL, NULL, NULL);
                  fclose(dhfile);
               }

               if (dhparam)
               {
                  EC_KEY *eckey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
                  if (eckey && EC_KEY_generate_key(eckey) == 1)
                  {
                     atexit(SSL_CTX_cleanup);

                     if ((gCTX = SSL_CTX_new(TLSv1_2_server_method())) &&
                         SSL_CTX_use_certificate_chain_file(gCTX, certchain) == 1 &&
                         SSL_CTX_use_RSAPrivateKey_file(gCTX, chainpkey, SSL_FILETYPE_PEM) == 1 &&
                         SSL_CTX_check_private_key(gCTX) == 1 &&
                         SSL_CTX_set_tmp_dh(gCTX, dhparam) == 1 &&
                         SSL_CTX_set_tmp_ecdh(gCTX, eckey) == 1 &&
                         SSL_CTX_set_cipher_list(gCTX, "HIGH:!aNULL:!SSLv3:!SSLv2") == 1 &&
                         SSL_CTX_set_options(gCTX, SSL_OP_SINGLE_DH_USE|SSL_OP_CIPHER_SERVER_PREFERENCE|SSL_OP_NO_SSLv2|SSL_OP_NO_SSLv3|SSL_OP_NO_TLSv1|SSL_OP_NO_TLSv1_1))
                     {
                        EC_KEY_free(eckey);
                        DH_free(dhparam);

                  #pragma mark ••• main() -- IPv4 any host TLS setup •••
                        if ((gListenSSockL_v4 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
                        {
                           syslog(LOG_ERR, "Error creating the secure IPv4 listening socket.");
                           exit(EXIT_FAILURE);
                        }

                        serverAddress_v4.sin_addr = tls_addr4;
                        serverAddress_v4.sin_port = htons(tls_port);
                        if (setsockopt(gListenSSockL_v4, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int)) < 0 ||
                            setsockopt(gListenSSockL_v4, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(int)) < 0 ||
                            bind(gListenSSockL_v4, (struct sockaddr *)&serverAddress_v4, sizeof(serverAddress_v4)) < 0)
                        {
                           syslog(LOG_ERR, "Error calling bind() on the TLS IPv4 socket: %d.", errno);
                           exit(EXIT_FAILURE);
                        }

                        if (listen(gListenSSockL_v4, 5) < 0)
                        {
                           syslog(LOG_ERR, "Error calling listen() on the TLS IPv4 socket.");
                           exit(EXIT_FAILURE);
                        }

                        if (rc = pthread_create(&thread, &detach, ssocklLoop, &gListenSSockL_v4))
                        {
                           syslog(LOG_ERR, "Cannot create thread for responding to IPv4 TLS client connections: %d.", rc);
                           exit(EXIT_FAILURE);
                        }

                  #pragma mark ••• main() -- IPv6 any host TLS setup •••
                        if ((gListenSSockL_v6 = socket(AF_INET6, SOCK_STREAM, 0)) < 0)
                        {
                           syslog(LOG_ERR, "Error creating the secure IPv6 listening socket.");
                           exit(EXIT_FAILURE);
                        }

                        serverAddress_v6.sin6_addr = tls_addr6;
                        serverAddress_v6.sin6_port = htons(tls_port);
                        if (setsockopt(gListenSSockL_v6, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int)) < 0 ||
                            setsockopt(gListenSSockL_v6, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(int)) < 0 ||
                            bind(gListenSSockL_v6, (struct sockaddr *)&serverAddress_v6, sizeof(serverAddress_v6)) < 0)
                        {
                           syslog(LOG_ERR, "Error calling bind() on the TLS IPv6 socket: %d.", errno);
                           exit(EXIT_FAILURE);
                        }

                        if (listen(gListenSSockL_v6, 5) < 0)
                        {
                           syslog(LOG_ERR, "Error calling listen() on the TLS IPv6 socket.");
                           exit(EXIT_FAILURE);
                        }

                        if (rc = pthread_create(&thread, &detach, ssocklLoop, &gListenSSockL_v6))
                        {
                           syslog(LOG_ERR, "Cannot create thread for responding to IPv6 TLS client connections: %d.", rc);
                           exit(EXIT_FAILURE);
                        }
                     }

                     else
                        syslog(LOG_WARNING, "Cannot establish TLS context - cert dir = %s.", certdir);
                  }

                  else
                     syslog(LOG_WARNING, "Cannot establish ECDH cryptography.");
               }

               else
                  syslog(LOG_WARNING, "DH parameter file not found: %s.", dh1024pem);
            }

            else
               syslog(LOG_WARNING, "Out of memory error during TLS thread setup.");
         }
      }


#pragma mark ••• main() -- main thread loop responding to Unix Domain Socket connections •••
      if (gid >= 0)              // gid needs to be set first
         if (setgid((gid_t)gid) == -1)
         {
            syslog(LOG_ERR, "The gid of the ContentCGI process could not be set to '%u'.\n", (gid_t)gid);
            exit(EXIT_FAILURE);
         }

      if (uid >= 0)
         if (setuid((uid_t)uid) == -1)
         {
            syslog(LOG_ERR, "The uid of the ContentCGI process could not be set to '%u'.\n", (uid_t)uid);
            exit(EXIT_FAILURE);
         }

      long double mt, lastfail = microtime();
      int err, socket;

      while (!gShutdownFlag)
      {
         if ((socket = accept(gListenSocket_ud, NULL, NULL)) < 0)
         {
            if (gShutdownFlag)
               exit(0);
            syslog(LOG_ERR, "Error calling accept(): %d.", err = errno);

            mt = microtime();
            if (err != ECONNABORTED && mt - lastfail < 0.01)
               exit(EXIT_FAILURE);           // it is fatal if subsequent calls to accept() fail rapidly (< 10 ms) in a row
            else
            {
               lastfail = mt;
               continue;                     // try again
            }
         }

         ConnExec *connex = allocate(sizeof(ConnExec), default_align, false);
         if (!connex)
         {
            syslog(LOG_ERR, "Insufficient memory for establishing a client connection.");
            shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating insufficient memory for any operations
            close(socket);
            exit(EXIT_FAILURE);
         }
         *connex = (ConnExec){{socket, 0, NULL}, 0, createTable(256), NULL, NULL, &socketRecv, &socketARcv, &socketSend, &socketJSnd, &socketShut};

         if (!connex->serverTable)
         {
            syslog(LOG_ERR, "Insufficient memory retrieving the connection meta data of the HTTP server.");
            shutdown(socket, SHUT_RDWR);     // this is a fatal error indicating insufficient memory for any operations
            close(socket);
            deallocate(VPR(connex), false);
            exit(EXIT_FAILURE);
         }

         setsockopt(connex->conn.sock, SOL_SOCKET, SO_NOSIGPIPE, &optval, sizeof(int));
         if (err = pthread_create(&thread, &detach, firstresponder, connex))
         {
            syslog(LOG_ERR, "Cannot create a new thread for responding to a client connection: %d.", err);
            shutdown(socket, SHUT_RDWR);
            close(socket);
            connexRelease(&connex);
            exit(EXIT_FAILURE);
         }
      }
   }

   else
   {
      syslog(LOG_ERR, "Cannot change working directory to web root = %s.", webroot);
      exit(EXIT_FAILURE);
   }

   exit(0);
}


#pragma mark ••• TLS pthread locking callback routines and set-/cleanup •••

static long            *lock_count;
static pthread_mutex_t *lock_cs;

unsigned long SSL_pthreads_id_callback(void)
{
   return (unsigned long)pthread_self();
}

void SSL_pthreads_locking_callback(int mode, int type, const char *file, int line)
{
   if (mode & CRYPTO_LOCK)
   {
      pthread_mutex_lock(&lock_cs[type]);
      lock_count[type]++;
   }
   else
      pthread_mutex_unlock(&lock_cs[type]);
}

boolean SSL_thread_setup(void)
{
   int i, n = CRYPTO_num_locks();

   if ((lock_count = allocate(n*sizeof(long), default_align, true)) &&
       (lock_cs    = allocate(n*sizeof(pthread_mutex_t), default_align, false)))
   {
      for (i = 0; i < n; i++)
         pthread_mutex_init(&lock_cs[i], NULL);

      CRYPTO_set_id_callback(SSL_pthreads_id_callback);
      CRYPTO_set_locking_callback(SSL_pthreads_locking_callback);
      return true;
   }

   return false;
}

void SSL_thread_cleanup(void)
{
   CRYPTO_set_id_callback(NULL);
   CRYPTO_set_locking_callback(NULL);

   int i, n = CRYPTO_num_locks();
   for (i = 0; i < n; i++)
      pthread_mutex_destroy(&lock_cs[i]);

   deallocate_batch(true, VPR(lock_cs),
                          VPR(lock_count), NULL);
}

void SSL_CTX_cleanup(void)
{
   if (gCTX)
      SSL_CTX_free(gCTX);
}

void urandom_close(void)
{
   close(gURandom);
}

void usocket_delete(void)
{
   unlink(usocket);
}
