#!/usr/bin/perl

#use strict;
use warnings;
use DBI;
use POSIX qw(strftime);
use Sys::HostAddr;

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
my $host="192.168.101.126";
my $user_name="deployer";
my $password="deployerlefu8";
my $port_num=undef;
my $socket_file=undef;

my $dsn="DBI:mysql:host=$host";
my %conn_attrs=(PrintError =>0,RaiseError =>1,AutoCommit =>0);

$dsn.=";database=$db_name" if defined $db_name;
$dsn.="mysql_socket=$socket_file" if defined $socket_file;
$dsn.=";port=$port_num" if defined $port_num;

my $dbh=DBI->connect($dsn,$user_name,$password,\%conn_attrs);
$dbh->do("SET NAMES 'utf8';");
my $table_name="tbl_customerservices_pv";
my @fields=qw/local_ip date_time url stat response request_sec src_ip/;

sub insert_hash {
        my ($table,$fields,$values) = @_;
        my $sql = sprintf "insert into %s (%s) values (%s)",
        $table, join(",", @$fields), join(",", ("?")x@$fields);
        my      $sth = $dbh->prepare_cached($sql);
        return $sth->execute(@$values);
}

open (FH,"tail -n 8000 $file |") || die "Cannot open '$file' for reading!";
#open (FH,$file) || die "Cannot open '$file' for reading!";
while(<FH>){
        my   @line=split(" ",$_);
        chomp(@line);
        #&insert_hash($table_name,\@fields,\@line);
        my $host=$line[0];$time=$line[3];$url=$line[6];$stat=$line[8];$response=$line[9];$request_sec=$line[10];$src_ip=$line[-1];
        $url=~s/\?.*$//;
        $url=~s/\/+/\//g;
        next unless $time=~/$min\d{2}$/;
        next if $host=~/^127.0.0.1/;
        if ($stat<100){
        $stat=$line[-5];$response=0;$request_sec=0
        }
        $time=~s/\[\d{2}.[^:]*://;
        $response=~tr/-/0/;
        my @items=($local_ip,$date.$time,$url,$stat,$response,$request_sec,$src_ip);
#        print join("\t",@items),"\n";
        &insert_hash($table_name,\@fields,\@items);
        $count++;
} 
$dbh->disconnect();
close(FH);
print "Total:".${count}."\n";

