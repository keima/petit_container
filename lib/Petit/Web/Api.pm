package Petit::Web::Api;
use Mojo::Base 'Mojolicious::Controller';
use IO::String;
use Archive::Zip qw/:ERROR_CODES/;
use File::Temp qw/tempfile/;
use Mojo::Util qw/slurp spurt/;
use Mojo::Upload;

# Basic Auth.
sub login {
    my $self = shift;

    if ( my $auth = $self->req->url->to_abs->userinfo ) {
        my ( $user, $pass ) = split /:/, $auth, 2;
        return 1 if $user eq $ENV{API_HTTP_USER} and $pass eq $ENV{API_HTTP_PASSWORD};
    }

    $self->res->headers->www_authenticate("Basic realm=bucket");
    $self->res->code(401);
    $self->res->body('Authorization required');
    $self->rendered;
    return undef;
}

#
# usage:
# curl -o export.zip https://*****
#
sub export {
    my $self = shift;
    my $redis = $self->app->store;

    # make temporary file
    my ($fh, $filename) = tempfile();
    my $zip = Archive::Zip->new();

    my @keys = $redis->keys('*');
    for my $key (@keys){
        # skip session cache.
        next if $key =~ /^cache/;

        # append data into temporary
        $zip->addString( $redis->get($key), $key);
    }

    unless ( $zip->writeToFileNamed($filename) == AZ_OK ) {
        die "error";
    }

    # serve temporary file to client
    $self->res->headers->content_disposition('attachment; filename=export.zip;');
    $self->render(data => slurp $filename);
}

#
# usage:
# curl -T export.zip https://*****
#
sub import {
    my $self   = shift;
    my $redis = $self->app->store;

    my $upload = Mojo::Upload->new;
    $upload->asset($self->req->content->asset);
    my $zip = Archive::Zip->new();

    my $data = $upload->slurp;
    # load object
    unless($zip->readFromFileHandle(IO::String->new($data)) == AZ_OK){
        die "can't readFromFileHandle(): $!";
    }

    my $result = 0;

    # extract
    my ($fh, $filename) = tempfile();
    my @members = $zip->memberNames();
    foreach (@members) {
        $zip->extractMember($_, $filename);
        my $key = $_;
        my $value = slurp($filename);

        # check item
        if($key and defined $value) {
            # into store.
            $redis->set($key, $value);
            $result++;
        }
    }

    $self->render(text => "import:" . $result . " items.\n");
}

1;

