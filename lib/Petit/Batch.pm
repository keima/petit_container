package Petit::Batch;

use Redis;
our $connection;

BEGIN {
    # parse redis connection url from env.
    my ($redis_auth, $redis_hostname);
    if (my $var = $ENV{REDISCLOUD_URL}){
        if( $var =~ m,redis://(.*):(.*)@(.*), ){
            $redis_auth = $2;
            $redis_hostname = $3;
        }
    }

    # redis connection
    $connection = Redis->new(
        server => $redis_hostname,
        password  => $redis_auth,
        reconnect => 2,
        every => 1_000_000,
        cnx_timeout => 60,
        encoding => undef
    );
}

sub new {
    my $class = shift;
    my $self  = {
        redis => $connection,
    };
    bless $self, $class;
}

sub redis {
    my $self = shift;
    return $self->{redis};
}

1;
