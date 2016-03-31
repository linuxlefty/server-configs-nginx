# Choose between www and non-www, listen on the *wrong* one and redirect to
# the right one -- http://wiki.nginx.org/Pitfalls#Server_Name
#
server {
  listen [::]:80 ipv6only=on;
  listen 80;

  # listen on both hosts
  server_name {{TARGET.HOST}} www.{{TARGET.HOST}};

  # and redirect to the https host (declared below)
  # avoiding http://www -> https://www -> https:// chain.
  return 301 https://{{TARGET.HOST}}$request_uri;
}

server {
  listen [::]:443 ssl spdy;
  listen 443 ssl spdy;

  # listen on the wrong host
  server_name www.{{TARGET.HOST}};

  include h5bp/directive-only/ssl.conf;

  # and redirect to the non-www host (declared below)
  return 301 https://{{TARGET.HOST}}$request_uri;
}

server {

  # listen [::]:443 ssl spdy accept_filter=dataready;  # for FreeBSD
  # listen 443 ssl spdy accept_filter=dataready;  # for FreeBSD
  # listen [::]:443 ssl spdy deferred;  # for Linux
  # listen 443 ssl spdy deferred;  # for Linux
  listen [::]:443 ssl spdy;
  listen 443 ssl spdy;

  # The host name to respond to
  server_name {{TARGET.HOST}};

  include h5bp/directive-only/ssl.conf;

  # Path for static files
  root {{PATHS.STATIC_ROOT}};

  #Specify a charset
  charset utf-8;

  # Custom 404 page
  error_page 404 /404.html;

  # Include the basic h5bp config set
  include h5bp/basic.conf;

  # Include wsgi config
  include lib/uwsgi.conf;
}
