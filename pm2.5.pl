#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use LWP::Simple;
use Encode;
use FindBin;
use lib $FindBin::Bin;
use class::jiepang;

while (1) {

	my $api = 'http://zx.bjmemc.com.cn/ashx/Data.ashx?Action=GetAQIClose1h';
	my $hs_pm;
	my $str = get($api);
	eval{  $hs_pm = decode_json($str ); };
	# 海淀北部新区-384-严重污染;海淀万柳-351-严重污染;昌平-378-严重污染;通州-462-严重污染;[01/14/2013 11:00:00]
	my @arr_palce = ("北部新区","万柳","昌平","通州");
	my %hs_place;
	foreach (@arr_palce) {
		$hs_place{$_} = "";
	}
	my $pubtime = '';
	foreach  (@{$hs_pm}) {
		my $nm_p  = encode('utf8',$_->{'StationName'});
		my $pm2p5 = encode('utf8',$_->{'AQIValue'});
		my $pmqul = encode('utf8',$_->{'Quality'});

		if (exists $hs_place{$nm_p}) {
			$hs_place{$nm_p} = $pm2p5.'-'.$pmqul;
			$pubtime = $_->{'Time'};
		}
	}

	my $content = "北京PM2.5: ";
	foreach  (@arr_palce) {
		$content .= $_."-".$hs_place{$_}.";";
	}
	$content =~ s/;$/./;
	$content .= "[$pubtime]";
	unless ($pubtime) {
		sleep 300;
		next;
	}
	my $jiepang = new class::jiepang({ApiConf=>"$FindBin::Bin/config/api.conf"});
	$jiepang->login({username=>"chrisfoon",password=>""});
	my $status = $jiepang->publish({pid=>'2DF32F50E0DB12',msg=>$content});

	if ($status eq 'error') {
		print "Publish Error!\n";
	}
	last;
}
#print $jiepang->search({Q=>"唐家岭新城"});