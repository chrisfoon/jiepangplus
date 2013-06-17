#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP;
use LWP::Simple;
use HTTP::Response;
use HTTP::Cookies::Netscape;

package class::jiepang;

sub new{
	my $class = shift;
	my $hs_path = shift;

	my $self = {};
	$self->{'APICONF'}   = '';
	$self->{'LOGININFO'} = {};
	
	if (exists $hs_path->{'ApiConf'}) {
		my $str;
		open my $apicfh,"<",$hs_path->{'ApiConf'} or die "Cann't OPen:$hs_path->{'ApiConf'}\n ";
		while (<$apicfh>) {
			$str .= $_;
		}
		close($apicfh);
		eval{ $self->{'APICONF'} = JSON::decode_json($str) };
	}
	
	bless $self , $class;
	return $self;
}

# ************
# 发布内容
# ************
sub publish{
	my $self	  = shift;
	my $hs_param  = shift;
	my $_SID_	  = $self->{'LOGININFO'}{'sid'};
	my $pub_uri = $self->{'APICONF'}{'API'}{'jp_publish'};
	   $pub_uri =~ s/{_SID_}/$_SID_/g;
	
	my @arr_postfields = (
		'id',$hs_param->{'pid'},
		'status',"$hs_param->{'msg'}",
		'douban',"'on'",
		'kaixin001','on',
		'qzone','on',
		'renren','on',
		'sina','on',
		);

	my $agent = 'Mozilla/5.0 (Windows NT 6.1; rv:11.0) Gecko/20100101 Firefox/11.0';
	my @ns_headers = (
		'User-Agent' => $agent,
		'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
		'Accept-Charset' => 'iso-8859-1,*,utf-8',
		'Accept-Language' => 'zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3',
	);

	my $browser = LWP::UserAgent->new;
	   $browser->parse_head(0);	# HTML::HeadParser模块在使用parse()方法时，对没有编码的UTF-8会弄混，要保证在传值之前进行适当的编码。

	push @{ $browser->requests_redirectable }, 'POST'; 
	$browser ->cookie_jar(HTTP::Cookies::Netscape->new( 'file' =>$self->{'LOGININFO'}{'cookie_jar'}, ));

	my $response = $browser->post($pub_uri,\@arr_postfields,@ns_headers);
	if ($response->is_success) {
		return $response->content;
	}
	else{
		return "error";
	}
}

#**************
# 查询地点信息
#**************
sub search{
	my $self	  = shift;
	my $hs_param  = shift;
	my $_SID_	  = $self->{'LOGININFO'}{'sid'};
	my $_KEYWORD_ = $hs_param->{"Q"};

	my $search_uri = $self->{'APICONF'}{'API'}{'jp_splace'};
	$search_uri =~ s/{_SID_}/$_SID_/g;
	$search_uri =~ s/{_KEYWORD_}/$_KEYWORD_/g;

	my $content = LWP::Simple::get($search_uri);
	my (@arr_list) = $content =~ /<p class="item"><a href="\/m\/venue\/(\w+)\?sid=$_SID_"><span class="location-name">(.*?)<\/span><\/a><br\/><span class="note">(.*?)<\/span><\/p>/g;
	my $list = "";
	for (my $i = 0;$i<=$#arr_list;$i+=3) {
		$list .= "$arr_list[$i]| $arr_list[$i+1]|$arr_list[$i+2]\n";
	}
	return $list;
}

# **********************************************
# 使用用户名和密码登录JiePang 保存Cookie信息
# **********************************************
sub login {
	my $self	 = shift;
	my $hs_param = shift;
	
	return 'No jp_login UIR' if not exists $self->{'APICONF'}{'API'}{'jp_login'};
	my $login_uri  = $self->{'APICONF'}{'API'}{'jp_login'};
	my $sid_uri	   = $self->{'APICONF'}{'API'}{'jp_sid'};

	my $username   = $hs_param->{'username'};
	my $password   = $hs_param->{'password'};

	# 保存cookie文件目录
	my $cookie_path = $self->{'APICONF'}{'LOCAL'}{'path_cookie'};
	

	my $cookie_jar  = $cookie_path."/jiepang_cookie_".Digest::MD5::md5_hex("$username$password");
	
	my $arr_postfields = ['user',$username,'pwd',$password];;

	my %hs_return;
	$hs_return{'cookie_jar'} = $cookie_jar;
	$hs_return{'user'}	     = $username;
	$hs_return{'password'}   = $password;
	
	# ****************
	# 登录 JiePang
	# ****************
	my $agent = 'Mozilla/5.0 (Windows NT 6.1; rv:11.0) Gecko/20100101 Firefox/11.0';
	my @ns_headers = (
		'User-Agent' => $agent,
		'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
		'Accept-Charset' => 'iso-8859-1,*,utf-8',
		'Accept-Language' => 'zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3',
	);
	my $browser = LWP::UserAgent->new;
	   $browser->parse_head(0);	# HTML::HeadParser模块在使用parse()方法时，对没有编码的UTF-8会弄混，要保证在传值之前进行适当的编码。
	# 对302 状态(重定向)的，执行自动处理
	$browser ->requests_redirectable(['POST','HEAD','GET']);
	$browser ->cookie_jar(HTTP::Cookies::Netscape->new(
		'file' =>$cookie_jar,
		'autosave'=>1,
	));
	$browser->get ($sid_uri);
	my $response = $browser->post($login_uri,$arr_postfields,@ns_headers);
	if ($response->is_success) {
		my $content = $response->content;
		my ($go) = $content =~ /<div id="header"><a href="\/m\/home\?sid=(\w+)"><img/;
		$hs_return{'sid'} = $go;
	}
	else{
		print "Require Error:". $response->status_line;
	}
	
	$self->{'LOGININFO'} = \%hs_return;
	return \%hs_return;
}

1;