#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use POSIX qw(strftime);
use Sys::HostAddr;
#use Date::Manip;

#get local ip
my $interface = Sys::HostAddr->new(ipv => '4', interface => 'eth0');
my $local_ip=$interface->main_ip;

my $file_name=strftime("localhost_access_log.%Y-%m-%d.txt", localtime(time));
#my $path='/opt/tomcat_agent/logs';
my $path=$ARGV[0];

if (!-d "$path")
{
        print "$path not exist!\n";
        exit 1;
}

my $file="$path/$file_name";

my $date=strftime("%Y-%m-%d ", localtime(time));
my $min=strftime("%H:%M:", localtime(time()-60));
my $count=0;

#DB 
my $db_name="customer";
my $table_name="tbl_customer_info";
my $host="x.x.x.x";
my $user_name="deployer";
my $password="deployer";
my $port_num=undef;
my $socket_file=undef;

my $dsn="DBI:mysql:host=$host";
my %conn_attrs=(PrintError =>0,RaiseError =>1,AutoCommit =>0);

$dsn.=";database=$db_name" if defined $db_name;
$dsn.="mysql_socket=$socket_file" if defined $socket_file;
$dsn.=";port=$port_num" if defined $port_num;

my $dbh=DBI->connect($dsn,$user_name,$password,\%conn_attrs);
$dbh->do("SET NAMES 'utf8';");

my @fields=qw/local_ip uid date_time sid src_ip stat url sname/;

sub insert_hash {
        my ($table,$fields,$values) = @_;
        my $sql = sprintf "insert into %s (%s) values (%s)",
        $table, join(",", @$fields), join(",", ("?")x@$fields);
        my      $sth = $dbh->prepare_cached($sql);
        return $sth->execute(@$values);
}

open (FH,"tail -n 3000 $file |") || die "Cannot open '$file' for reading!";
#open (FH,$file) || die "Cannot open '$file' for reading!";
while(<FH>){
	my $line=$_;
	chomp($line);
	next unless $line=~/$min\d{2}\s/;
	next unless $line=~/\d{11},.+\.\d{3}$/;
	my $url=$line;my $src_ip=$line;my $stat=$line;my $date_time_str=$line;
	$url=~s/^.+[GET|POST]\s(.+)\sHTTP\/.+$/$1/;
	next unless $url=~/\.action|\.htm/;
	#next if $url=~/\.[gif|css|js|jpg]/;
	$src_ip=~s/^.+\s(\d{1,3}(\.\d{1,3}){3}.+)$/$1/;s/\s+//g;
	$stat=~s/^.+HTTP.+\"\s(\d{3})\s.+$/$1/;
	$date_time_str=~s/^.+\d{4}:(\d{2}:\d{2}:\d{2})\s.+$/$1/;
	$line=~s/^.+\s(\d{11},.+,\d{10})\s.+$/$1/;
	my @row=split(",",$line);
	my $uid=$row[0];
	my $sname=$row[1];
	my $sid=$row[2];
#	print $date,$date_time_str."\n";
	my $date_time="$date $date_time_str";
	#chomp($date_time);
	my @items=($local_ip,$uid,$date_time,$sid,$src_ip,$stat,$url,$sname);
	print join("\t",@items),"\n";
        &insert_hash($table_name,\@fields,\@items);
        $count++;
} 
$dbh->disconnect();
close(FH);
print "Total:".${count}."\n";

