package Petit::Web;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Web::Auth;
use Mojolicious::Plugin::SessionStore;
use Plack::Session::Store::Cache;
use Redis;
use Cache::Redis;

sub startup {
    my $self = shift;

    # parse redis connection url from env.
    my ($redis_auth, $redis_hostname);
    if (my $var = $ENV{REDISCLOUD_URL}){
        if( $var =~ m,redis://(.*):(.*)@(.*), ){
            $redis_auth = $2;
            $redis_hostname = $3;
        }
    }

    # redis connection
    my $redis = Redis->new(
        server => $redis_hostname,
        password  => $redis_auth,
        reconnect => 2,
        every => 1_000_000,
        cnx_timeout => 60,
        encoding => undef
    );

    # construct redis accessor
    $self->attr(store => sub { $redis; });

    # set a session store
    $self->plugin('SessionStore', { session_store =>
        Plack::Session::Store::Cache->new(
            cache => Cache::Redis->new(
                redis => $redis,
                namespace => 'cache:',
            ),
        )
    });

    # cookie 1month
    $self->sessions->default_expiration(86400 * 30);

    # auth for twitter
    $self->plugin('Web::Auth',
        module      => 'Twitter',
        key         => $ENV{TWITTER_CONSUMER_KEY},
        secret      => $ENV{TWITTER_CONSUMER_SECRET},
        on_finished => sub {
            my ( $s, $access_token, $access_secret, $ref ) = @_;
                $s->session('access_token',         $access_token);
                $s->session('access_token_secret',  $access_secret);
                $s->session('screen_name',          $ref->{screen_name});
                $s->session('user_id',              "TWITTER::" .$ref->{id});
            },
    );

    # router
    my $r = $self->routes;

    # router on logging
    my $r_logging = $r->under->to('pages#is_logging');

    # router on management api
    my $r_manage_api = $r->bridge->to('manage#login');

    # normal
    $r->any('/login')->to('pages#login');
    $r->post('/logout')->to('pages#logout');
    $r->get('/auth/*method/callback')->to('pages#auth_callback');

    # logging
    $r_logging->get('/')->to('pages#index');

    # login check api
    $r->get('/api/is_logged_in')->to('pages#check');

    # data store api
    $r->options('/api/store/*')->to('pages#cors'); # <- CORS OPTION method
    $r_logging->any([qw(GET POST DELETE)] => '/api/store/:target')
        ->to(controller => 'store', action => 'store', target => undef);

    # managing api (import,export)
    $r_manage_api->route('/api/manage/:action')->to(controller => 'manage');

    # output headers
    $self->app->hook( after_dispatch => sub {
        my $s = shift;
        $s->res->headers->header( 'X-Content-Type-Options' => 'nosniff');
        $s->res->headers->header( 'X-Frame-Options'        => 'deny');
        $s->res->headers->header( 'Cache-Control'          => 'no-cache');
        $s->res->headers->header( 'Access-Control-Allow-Origin' => $ENV{ACCESS_CONTROL_ALLOW_ORIGIN});
        $s->res->headers->header( 'Access-Control-Allow-Credentials' => 'true');
        $s->res->headers->header( 'Access-Control-Allow-Methods' => 'POST, GET, DELETE');
        $s->res->headers->header( 'Access-Control-Allow-Headers' => 'X-Requested-With, Origin, Content-Type, Accept');
        $s->res->headers->header( 'Access-Control-Max-Age' => 3600 );
        $s->res->headers->header( 'P3P' => "CP='UNI CUR OUR'" ); # TBD
    });
}

1;
