package Petit::Web::Pages;
use Mojo::Base 'Mojolicious::Controller';

# check login
sub is_logging {
    my $self = shift;
    # exist session?
    if ( $self->session('user_id') ) {
        # for api. ex. data store
        if( $self->req->url->path =~ m,api, ){
            # origin check
            if ($self->req->headers->origin eq $ENV{ACCESS_CONTROL_ALLOW_ORIGIN}){
                return 1;
            }
            $self->render(json => {_code => 403}, status => 403);
            return undef;
        }
        return 1;
    }
    else {
        if( $self->req->url->path =~ m,api, ){
            # for api. ex. data store : state unauthorized
            $self->render(json => {_code => 401}, status => 401);
            return undef;
        }else{
            return $self->redirect_to('login');
        }
    }
}

sub check {
    my $self = shift;
    if ( $self->session('user_id') ) {
        $self->render(json => {_code => 204, message => "You are logged-in."}, status => 204);
    } else {
        $self->render(json => {_code => 401, message => "Not logged-in. Unauthorized."}, status => 401);
    }
}

sub login {
    my $self = shift;
    # exist session?
    if ( $self->session('user_id') ) {
        return $self->redirect_to("/");
    }
    # on POST request redirect to authenticate
    if (uc $self->req->method ne 'POST') {
        return;
    }
    my $service = $self->req->param("service");
    if ($service eq "twitter") {
        return $self->redirect_to("/auth/twitter/authenticate");
    }
}

sub logout {
    my $self = shift;
    # session expires.
    $self->session( expires => 1 );
    $self->redirect_to('/');
}

# authenticate callback.
sub auth_callback {
    my $self = shift;
    $self->session_options->{change_id}++; # replace new session.
    $self->redirect_to($ENV{LOGIN_AFTER_REDIRECT});
}

sub index {}

# for cors pre-flight.
sub cors {
    my $self = shift;
    my $cors = <<AAA;
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration>
<CORSRule>
<AllowedOrigin>%s</AllowedOrigin>
<AllowedMethod>POST</AllowedMethod>
<MaxAgeSeconds>3600</MaxAgeSeconds>
<AllowedHeader>X-Requested-With, Origin, Content-Type, Accept</AllowedHeader>
</CORSRule>
</CORSConfiguration>
AAA

    $self->render(text => sprintf($cors, $ENV{ACCESS_CONTROL_ALLOW_ORIGIN}));
}

1;
