package Petit::Web::Pages;
use Mojo::Base 'Mojolicious::Controller';

sub is_logging {
    my $self = shift;
    # exist session?
    if ( $self->session('user_id') ) {
        return 1;
    }
    else {
        if( $self->req->url->path =~ m,store, ){
            # for data store : state unauthorized
            $self->render(json => {_code => 401});
            return undef;
        }else{
            # save url for redirect after logging
            return $self->redirect_to('login');
        }
    }
}

sub login {
    my $self = shift;
    # on POST request redirect to authenticate
    if (uc $self->req->method ne 'POST') {
        return;
    }
    my $service = $self->req->param("service");
    if ($service eq "twitter") {
        return $self->redirect_to( sprintf( "/auth/twitter/authenticate", ) );
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

