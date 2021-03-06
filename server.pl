#!/usr/bin/env perl

#
#   refer:
#   http://blog.nomadscafe.jp/2014/07/heroku-proclet.html
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Proclet;
use Plack::Loader;
use Getopt::Long;
use Mojo::Server::PSGI;
use Plack::Builder;
use Petit::Web;

my $port = 5000;
Getopt::Long::Configure ("no_ignore_case");
GetOptions(
    "p|port=s" => \$port,
);

chdir($FindBin::Bin);
my $proclet = Proclet->new(
    color => 1
);

my $psgi = Mojo::Server::PSGI->new( app => Petit::Web->new );
my $app = $psgi->to_psgi_app;
$proclet->service(
    code => sub {
        my $loader = Plack::Loader->load(
            'Starlet',
            port => $port,
            host => 0,
            max_workers => 5,
        );
        $loader->run($app);
    },
    tag => 'web',
);

# if no use scheduler.
#
#use HTTP::Tiny;
#if( $ENV{DYNO} ) {
#$proclet->service(
#    every => '*/30 * * * *',
#    tag => 'ping',
#    code => sub {
#        my $ua = HTTP::Tiny->new;
#        $ua->get("http://******.herokuapps.com");
#    }
#);
#}

$proclet->run;

