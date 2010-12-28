#!/usr/bin/perl -w
# Created @ 28.12.2010 by TheFox@fox21.at
# Version: 1.0.0
# Copyright (c) 2010 TheFox

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

# Description:
# Find non-linked directories and files on a domain.


use strict;
use FindBin;
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST HEAD);

$| = 1;

my $USERAGENT = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.8.1.20) Gecko/20081217 Firefox/2.0.0.20';
my $ua = LWP::UserAgent->new('max_redirect' => 0);
my $req;
my $res;
my $content;
$ua->agent($USERAGENT);

sub main{
	
	chdir $FindBin::Bin;
	
	my $baseurl = '';
	my $modeForce = 0;
	if(@ARGV){
		for my $arg (@ARGV){
			if($arg eq '-f'){
				$modeForce = 1;
			}
			else{
				$baseurl = $arg;
			}
		}
	}
	else{
		usagePrint();
	}
	if(!$modeForce && $baseurl !~ /\/$/){
		print STDERR "Maybe the baseurl '$baseurl' is wrong.\nIt must have a '/' at the end.\nIf you know what you do run this with force mode (-f):\n$0 -f '$baseurl'\n";
		exit 1;
	}
	
	my @DB = ();
	my @DBtmp = ();
	open DBF, '<', 'dictionary.txt';
	@DBtmp = split(/\n/, join('', <DBF>));
	close DBF;
	
	@DB = grep{$_ !~ /^#/ && $_ ne ''} @DBtmp;
	
	print "baseurl: $baseurl\n";
	print "db items: ".@DB."\n";
	
	my $filesC = 0;
	my $filesOk = 0;
	my $filesOk3xx = 0;
	
	for my $file (@DB){
		chomp $file;
		$filesC++;
		
		my $fullurl = "$baseurl$file";
		printf "%3d%% $fullurl ... ", $filesC / @DB * 100;
		
		#$req = GET($fullurl);
		$req = HEAD($fullurl);
		$res = $ua->request($req);
		
		my $resCode = $res->code();
		
		# 200 OK
		# 301 Moved Permanently
		# 302 Found
		# 303 See Other
		# 304 Not Modified
		if($resCode == 200 || ($resCode >= 301 && $resCode <= 304) || $resCode == 403){
			print "OK $resCode\n";
			$filesOk++;
			
			if($resCode >= 300 && $resCode <= 399){
				$filesOk3xx++;
			}
		}
		else{
			print "\r".(' ' x 79)."\r";
		}
		
		#sleep 1;
	}
	print "100% finished\n";
	
	print "\n";
	print "db items: ".@DB."\n";
	print "files ok all: $filesOk\n";
	print "files ok 3xx: $filesOk3xx\n";
	
	if($filesOk3xx / $filesOk >= 0.9){
		print "\nMaybe the server has a 'RewriteEngine'.\n";
	}
	
	print "\nexit\n";
	
	1;
}

sub usagePrint{
	print STDERR "Usage: $0 [-f] BASEURL\n";
	exit 1;
}

main();


# EOF
