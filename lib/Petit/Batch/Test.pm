package Petit::Batch::Test;
use base qw/Petit::Batch/;
use strict;

sub run {
    my $self  = shift;
    my $redis = $self->redis;

    my @keys = $redis->keys('*');
    for my $key (@keys){
        warn $key;
        if ($key =~ m,^cache,){
            warn "skip session cache.";
            next;
        }
        warn $redis->get($key);
#       $redis->del($key);
    }
}

1;
