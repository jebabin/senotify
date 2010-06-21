#!/usr/bin/env perl

# Author: Jean-Edouard BABIN, jeb in jeb.com.fr

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Todo:
#	- Improve tag filter
#	- Support other notificaton system

# For history see the end of the script

use strict;
use warnings;

use JSON;
use Data::Dumper;
use Getopt::Long;
use Compress::Zlib;
use LWP::UserAgent;
use File::Basename;
use File::Spec::Functions qw(rel2abs);

my %default_config;
my %opts;

###### Configuration

my $key = 'W2cJqWcKa0OFBM6OCsS2JA';
my $growlnotifypath = '"C:\Program Files\Growl for Windows\growlnotify"'; # For windows only


$default_config{'site'} = ['serverfault', 'superuser']; # serverfault | stackoverflow | superuser | meta.stackoverflow | stackapps
$default_config{'refresh'} = '300';
$default_config{'growl'} = '0';
$default_config{'excludetag'} = [];

###### Do not edit bellow

GetOptions(\%opts, 'site|s=s@', 'excludetag|e=s@', 'refresh|r=i', 'growl|g', 'help|h');

$opts{'site'} = $opts{'site'}               || $default_config{'site'};
$opts{'refresh'} = $opts{'refresh'}         || $default_config{'refresh'};
$opts{'growl'} = $opts{'growl'}             || $default_config{'growl'};
$opts{'excludetag'} = $opts{'excludetag'}   || $default_config{'excludetag'};

if (defined($opts{'help'})) {
	print STDERR "Usage: $0 [-r refresh] [-g] [[-e tag] [-e tag] ... ] [[-s site] [-s site] ... ]\n";
	print STDERR "    -s,--site        Site to monitor, one of serverfault | stackoverflow | superuser | meta.stackoverflow | stackapps\n";
	print STDERR "                     default to ".join(',',@{$default_config{'site'}})."\n";
	print STDERR "                     can be repeated many time\n";
	print STDERR "    -g,--growl       Enable growl notification (need growlnotify)\n";
	print STDERR "                     Growl for mac : http://growl.info/\n";
	print STDERR "                     Growl for windows : http://www.growlforwindows.com/\n";
	print STDERR "    -e,--excludetag  Exclude question contains these tags\n";
	print STDERR "                     can be repeated many time\n";
	print STDERR "    -r,--refresh     Refresh rate in seconds, default to 300 seconds\n";
	exit;
}

if ($opts{'growl'} && ($^O ne 'darwin') && ($^O ne 'MSWin32')) {
	warn "growl can only be used on Mac OS X and Windows";
}

my $ua = LWP::UserAgent->new;
$ua->agent("SENotify/0.2");
$ua->env_proxy();

my %lastquestionts;
foreach my $site (@{$opts{'site'}}) {
	$lastquestionts{$site} = time;
}

while (sleep $opts{'refresh'}) {
	foreach my $site (@{$opts{'site'}}) {
		my $moredata = 1;
		my $i = 0;
		while($moredata) {
			$i++;
			print 'http://api.'.$site.'.com/0.8/questions?sort=creation&order=asc&fromdate='.$lastquestionts{$site}.'&pagesize=10&page=1&key='.$key . "\n";
			my $req = HTTP::Request->new(GET => 'http://api.'.$site.'.com/0.8/questions?sort=creation&order=asc&fromdate='.$lastquestionts{$site}.'&pagesize=10&page=1&key='.$key);
			my $res = $ua->request($req);
		
			if ($res->is_success) {
				my $unzipped = Compress::Zlib::memGunzip($res->content); 
				my $result = decode_json($unzipped);
	
				$moredata = 0 if ($result->{'total'} <= $result->{'pagesize'});
				print $result->{'total'} . " question found on $site at : " . localtime() . "\n\n" if ($i == 1);
		
				foreach my $i (@{$result->{questions}}) {
					my $skip = 0;

					foreach my $qtag (@{$i->{'tags'}}) {
						foreach my $excludedtag (@{$opts{'excludetag'}}) {
							$skip = 1 if ($excludedtag eq $qtag);
						}
					}

					$lastquestionts{$site} = $i->{creation_date} + 1; # Bad Hack - Could make question to be lost if two question has same creation_id			

					next if $skip;
					
					if ($opts{'growl'}) {
						if ($^O eq 'darwin') {
							open(OUT, '| growlnotify -n SENotify --image '.dirname(rel2abs($0)).'/logo/'.$site.'.png') or warn "Error: Couldn't open the pipe to growlnotify $!";
							print OUT '(v:'. $i->{view_count} .'|a:'. $i->{answer_count} . ') ' .$i->{title} . "\n";
							print OUT '['.join('] [',@{$i->{tags}}).']' . "\n";
							close(OUT);
						} elsif ($^O eq 'MSWin32')  {
							my $message = '"(v:'. $i->{view_count} .'|a:'. $i->{answer_count} . ') ' .$i->{title} . '\n['.join('] [',@{$i->{tags}}).']"';
							system($growlnotifypath, '/i:'.dirname(rel2abs($0)).'/logo/'.$site.'.png', $message);	
						}
					}
										
					print '(v:'. $i->{view_count} .'|a:'. $i->{answer_count} . ') ' .$i->{title} . "\n";
					print '['.join('] [',@{$i->{tags}}).']' . "\n";
					print 'http://www.'.$site.'.com/questions/'.$i->{question_id}."\n";
					print "\n";
		
				}
			} else {
				warn "Unable to retrieve data (".$res->status_line.")";
				$moredata = 0;
			}
		}
	}
}

__END__

History (not following commit revision)

Revision 0.2 - 2010/06/22
- Add proxy support
- Add Windows growl support
- Use API Key
- Provide logo and suppress --image option
- Add question URL to terminal output
- Better query to API
- Show number of new question in terminal output
- Add view count to output
- Support multiple --site argument to monitor many site at once
- Support tag exclusion with --excludetag

Revision 0.1 - 2010/06/21
- Initial commit