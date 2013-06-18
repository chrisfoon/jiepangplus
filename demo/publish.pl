#!/usr/bin/perl
# *******************************************
# Copyright (C) 2013 JiePangPlus
# All rights reserved.
#
# 项目名称 : JP+
# 文件名称 : publish.pl
# 摘    要 : 发布信息Demo
# 作    者 : ChrisFu
# 创    建：2013/6/18
# 版    本：1.0
# *******************************************
use strict;
use FindBin;
use lib "$FindBin::Bin/../";
use class::jiepang;

my $content   = "和大伙儿说说Perl的这点事儿";
my $jiepang   = new class::jiepang({ApiConf=>"$FindBin::Bin/../config/api.conf"});
my $user_conf = $jiepang->loadconf("$FindBin::Bin/../config/chrisfoon.conf");

# 登录
$jiepang->login({username=>"$user_conf->{USER}{name}" ,password=>"$user_conf->{USER}{pwd}"});

# 发布
my $status = $jiepang->publish({pid=>"$user_conf->{PLACE}[1]{pid}",msg=>$content});
$status ne 'error' ? print "Publish Success!\n" : print "$status\n";