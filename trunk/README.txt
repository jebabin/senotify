### About

This perl script is a notification tool of new question on Stack Exchange website.
It supports output to terminal (STDOUT) as well as Growl (on both Mac OS X and Windows)


### Prerequist

To use it you need Perl and the following Perl module
- JSON
- LWP::UserAgent

You can do so with the following command (sudo is optional)
sudo cpan -i JSON
sudo cpan -i LWP::UserAgent

ActivePerl for Windows comes with both module included
Mac OS X users will have to install JSON module


### Growl

Mac OS X and Windows users can take advantage of Growl notification.
See http://growl.info/ for Mac users
See http://www.growlforwindows.com/gfw/ for Windows users

Mac users: in the Growl image disk, install growlnotify located in the Extras direcotry


### Usage

Usage: SENotify.pl [-r refresh] [-g] [[-e tag] [-e tag] ... ] [[-s site] [-s site] ... ]
    -s,--site        Site to monitor, one of serverfault | stackoverflow | superuser | meta.stackoverflow | stackapps
                     default to serverfault,superuser
                     can be repeated many time
    -g,--growl       Enable growl notification (need growlnotify)
                     Growl for mac : http://growl.info/
                     Growl for windows : http://www.growlforwindows.com/
    -e,--excludetag  Exclude question contains these tags
                     can be repeated many time
    -r,--refresh     Refresh rate in seconds, default to 300 seconds

Example :	perl SENotify.pl -g -e windows-7 -e outlook -s superuser
			Will show every 300 seconds new question of superuser excluding one with tag outlook or windows-7
			
			
### Website

http://code.google.com/p/senotify/
http://stackapps.com/questions/817


### Author

Jean-Edouard Babin - jeb in jeb.com.fr