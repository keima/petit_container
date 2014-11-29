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
            # for data store
            $self->render_not_found;
        }else{
            # save url for redirect after logging
            $self->session( redirect_path => $self->req->url->path );
            $self->redirect_to('login');
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
    my $self     = shift;
    my $redirect = $self->session("redirect_path");
    $self->redirect_to($redirect);
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

