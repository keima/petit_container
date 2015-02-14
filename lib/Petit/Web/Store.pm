package Petit::Web::Store;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/sha1_sum/;
use Mojo::JSON qw/decode_json encode_json/;

sub _key_generator {
    my $self = shift;
    my $key  = $self->stash('target');
    my $prefix = $self->session('user_id');
    return sprintf "%s:%s", $prefix, sha1_sum($key);
}

sub store {
    my $self = shift;
    my $method = lc $self->req->method;
    if ($self->can($method)) {
        return $self->$method();
    }
    $self->render(json => {_code => 503}, status => 503);
}

sub get {
    my $self = shift;
    my $key  = $self->_key_generator;
    my $redis = $self->app->store;

    if (my $data = $redis->get($key)) {
        return $self->render(data => $data, format => 'json' );
    }
    $self->render(json => {_code => 404}, status => 404);
}

sub post {
    my $self = shift;
    my $key  = $self->_key_generator;
    my $redis = $self->app->store;
    my $data = $self->req->json;
    $redis->set($key, encode_json($data));
    $self->render(json => {_code => 201}, status => 201);
}

sub delete {
    my $self = shift;
    my $key  = $self->_key_generator;
    my $redis = $self->app->store;
    if ( $redis->del($key) ){
        $self->render(json => {_code => 200}, status => 200);
    }else{
        $self->render(json => {_code => 404}, status => 404);
    }
}

1;
