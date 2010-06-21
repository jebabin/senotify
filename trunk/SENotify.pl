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
#	- Filters
#	- Use Mac::Growl for Growl
#	- Support other Notificaton system

# For history see the end of the script

use strict;
use warnings;

use JSON;
use Data::Dumper;
use Getopt::Long;
use Compress::Zlib;
use LWP::UserAgent;

my %default_config;
my %opts;

GetOptions(\%opts, 'image|i=s', 'site|s=s', 'refresh|r=i', 'growl|g', 'help|h');

$default_config{'site'} = 'serverfault'; # serverfault | stackoverflow | superuser | meta.stackoverflow | stackapps
$default_config{'refresh'} = '300';
$default_config{'growl'} = '0';
$default_config{'image'} = '';

$opts{'site'} = $opts{'site'}       || $default_config{'site'};
$opts{'refresh'} = $opts{'refresh'} || $default_config{'refresh'};
$opts{'growl'} = $opts{'growl'}     || $default_config{'growl'};
$opts{'image'} = $opts{'image'}     || $default_config{'image'};

if (defined($opts{'help'})) {
	print STDERR "Usage: $0 [-s site] [-r refresh] [-g] [-i image]\n";
	print STDERR " -s|--site : Site to monitor, one of serverfault | stackoverflow | superuser | meta.stackoverflow | stackapps, default to ".$default_config{'site'}."\n";
	print STDERR " -r|--refresh : Refresh rate in seconds, default to 300 seconds\n";
	print STDERR " -g|--growl : Enable growl notification (need growlnotify)\n";
	print STDERR " -i|--image : Image to use for growl notification\n";
	exit;
}

my $ua = LWP::UserAgent->new;
$ua->agent("SEPNotification/0.1");

my $req = HTTP::Request->new(GET => 'http://api.'.$opts{'site'}.'.com/0.8/questions?sort=creation&pagesize=1');
my $res = $ua->request($req);

my $lastquestion = 0;
if ($res->is_success) {
		my $unzipped = Compress::Zlib::memGunzip($res->content); 
		my $result = decode_json($unzipped);
		$lastquestion = $result->{questions}[0]{question_id};;
} else {
	die "Unable to retrieve data (".$res->status_line.")";
}

while (sleep $opts{'refresh'}) {
	my $req = HTTP::Request->new(GET => 'http://api.'.$opts{'site'}.'.com/0.8/questions?sort=creation&pagesize=10');
	my $res = $ua->request($req);

	if ($res->is_success) {
		my $unzipped = Compress::Zlib::memGunzip($res->content); 
		my $result = decode_json($unzipped);

		my $current_lastquestion = $result->{questions}[0]{question_id};

		print "Question found at : " . localtime() . "\n\n";

		foreach my $i (@{$result->{questions}}) {
			if ($i->{question_id} == $lastquestion) {
				last;
			} else {
				if ($opts{'growl'}) {
					if ($opts{'image'} ne '') {
						open(OUT, '| growlnotify --image '.$opts{'image'}) or warn "Error: Couldn't open the pipe to growlnotify $!";
					} else {
						open(OUT, '| growlnotify') or warn "Error: Couldn't open the pipe to growlnotify $!";							
					}
					print OUT '('. $i->{answer_count} . ') ' .$i->{title} . "\n";
					print OUT '['.join('] [',@{$i->{tags}}).']' . "\n";
					close(OUT);
				}
				print '('. $i->{answer_count} . ') ' .$i->{title} . "\n";
				print '['.join('] [',@{$i->{tags}}).']' . "\n";
				print "\n";

			}
		}

		$lastquestion = $current_lastquestion;

	} else {
		warn "Unable to retrieve data (".$res->status_line.")";
	}
}

__END__

History (not following commit revision)

Revision 0.1 2010/06/21
- Initial commit