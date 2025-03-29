Docker image that runs rtorrent and wireguard together to allow private, isolated torrenting within a terminal.

rTorrent and other packages are compiled from source to enable c-ares for curl.  
Defaults are very opinionated as this was made for my own personal use. Namely, the run command, rtorrent config, the user in Dockerfile, and the use of natpmp.  
