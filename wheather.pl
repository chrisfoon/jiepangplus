#!/usr/bin/perl -w
# *******************************************
# Copyright (C) 2012 WBPlus
# All rights reserved.
#
# 项目名称 : WB+
# 文件名称 : login.cgi
# 摘    要 : 登录接口
# 作    者 : ChrisFu
# 创    建：2012/4/10
# 版    本：1.0
# *******************************************
# 支持两种请求方式:
#	1. 后台执行:(共2个参数,第奇数个是参数名,第偶数个是参数值。)
#		perl ./login.cgi user 用户帐号 password 用户密码
#	2. http请求:
#		http://boss.sina.com.cn/wbplus/login.cgi?user=用户帐号&password=用户密码
# 返回结果：
# 第一行为状态值：0->发送失败;1->发送成功
# 第二行起为内容：如果状态为0，则第二行起为错误内容。如果状态为1，则返回用户详细内容
# *******************************************
use strict;
use warnings;
use JSON;
use LWP::Simple;
use Encode;
use FindBin;
use lib $FindBin::Bin;
use class::jiepang;


while (1) {

	my @arr_week = ('星期日','星期一','星期二','星期三','星期四','星期五','星期六');
	my $hs_wheather;
	my $wh_info = get("http://m.weather.com.cn/data/101010200.html");

	$wh_info = encode("utf8",$wh_info);
	eval{  $hs_wheather = decode_json($wh_info) };
	my ($d,$m,$y,$w) = (localtime(time()))[3,4,5,6];
	$y+=1900;
	$m++;
	my $today = sprintf("%04d年%02d月%02d日(%s)",$y,$m,$d,$arr_week[$w]);

	my ($tw) = (localtime(time()+86400))[6];
	my $next_week = $arr_week[$tw];

	my ($tbw) = (localtime(time()+86400*2))[6];
	my $next_b_week = $arr_week[$tbw];


	my $city  = encode('utf8',$hs_wheather->{'weatherinfo'}{'city'});
	my $date  = $hs_wheather->{'weatherinfo'}{'date_y'};
	my $week  = $hs_wheather->{'weatherinfo'}{'week'};

	my $whea  = encode('utf8',$hs_wheather->{'weatherinfo'}{'weather1'});
	my $whea2 = encode('utf8',$hs_wheather->{'weatherinfo'}{'weather2'});
	my $whea3 = encode('utf8',$hs_wheather->{'weatherinfo'}{'weather3'});

	my $temp  = encode('utf8',$hs_wheather->{'weatherinfo'}{'temp1'});
	my $temp2 = encode('utf8',$hs_wheather->{'weatherinfo'}{'temp2'});
	my $temp3 = encode('utf8',$hs_wheather->{'weatherinfo'}{'temp3'});

	my $wind  = encode('utf8', $hs_wheather->{'weatherinfo'}{'wind1'});
	my $wind2 = encode('utf8',$hs_wheather->{'weatherinfo'}{'wind2'});
	my $wind3 = encode('utf8',$hs_wheather->{'weatherinfo'}{'wind3'});

	unless ($whea) {
		sleep 300;
		next;
	}
	
	# EFB6EC4CEC5C4C77CB546FE94BC819AC 智学苑
	# 
	my $username = 'chrisfoon';
	my $password = '';


	#my $pid		 = 'EFB6EC4CEC5C4C77CB546FE94BC819AC';
	my $pid		 = '2C306029FC0728';# 唐家岭新城
	my $content  = "$today $city\:$whea $temp $wind;$next_week:$whea2 $temp2 $wind2;$next_b_week:$whea3 $temp3 $wind3";

	my $jiepang = new class::jiepang({ApiConf=>"$FindBin::Bin/config/api.conf"});
	$jiepang->login({username=>$username,password=>$password});
	my $status = $jiepang->publish({pid=>'2C306029FC0728',msg=>$content});

	if ($status eq 'error') {
		print "Publish Error!\n";
	}

	last;
}

#print $jiepang->search({Q=>"唐家岭新城"});