package ECPDF::Client::REST;
use base qw/ECPDF::BaseClass/;
use ECPDF::ComponentManager;
use ECPDF::Log;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use Data::Dumper;
use Carp;
use URI::Escape qw/uri_escape/;

sub classDefinition {
    return {
        ua    => 'LWP::UserAgent',
        proxy => '*',
        oauth => '*'
    };
}

sub new {
    my ($class, $params) = @_;

    logDebug("Creating ECPDF::Client::Rest with params: ", Dumper $params);
    if (!$params->{ua}) {
        $params->{ua} = LWP::UserAgent->new();
    }
    if ($params->{proxy}) {
        logDebug("Loading Proxy Component on demand.");
        my $proxy = ECPDF::ComponentManager->loadComponent('ECPDF::Component::Proxy', $params->{proxy});
        logDebug("Proxy component has been loaded.");
        $proxy->apply();
        $params->{ua} = $proxy->augment_lwp($params->{ua});
    }

    my $oauth = undef;
    if ($params->{oauth}) {
        # op stands for ouathParams
        my $op = $params->{oauth};

        if ($op->{oauth_version} ne '1.0') {
            croak "Currently OAuth version $op->{oauth_version} is not supported. Suported versions: 1.0";
        }

        for my $p (qw/request_method oauth_signature_method oauth_version request_token_path authorize_token_path access_token_path/) {
            if (!defined $op->{$p}) {
                croak "$p is mandatory for oauth component";
            }
        }
        logDebug("Loading ECPDF::Component::OAuth");
        $oauth = ECPDF::ComponentManager->loadComponent('ECPDF::Component::OAuth', $params->{oauth});
        logDebug("OAuth component has been loaded.");
    }
    my $self = $class->SUPER::new($params);

    if ($oauth) {
        $oauth->ua($self);
    }

    return $self;

}

sub newRequest {
    my ($self, @params) = @_;

    my $req = HTTP::Request->new(@params);
    my $proxy = $self->getProxy();
    if ($proxy) {
        my $proxyComponent = ECPDF::ComponentManager->getComponent('ECPDF::Component::Proxy');
        $req = $proxyComponent->augment_request($req);
    }
    return $req;
}


sub doRequest {
    my ($self, @params) = @_;

    my $ua = $self->getUa();
    return $ua->request(@params);
}


sub augmentUrlWithParams {
    my ($self, $url, $params) = @_;

    if (!$url) {
        croak "URL expected";
    }
    if (!ref $params) {
        croak "Required HASH reference for params";
    }

    $url =~ s|\/*?$||gs;
    my $gs = '';
    for my $k (keys %$params) {
        $gs .= uri_escape($k) . '=' . uri_escape($params->{$k}) . '&';
    }
    $gs =~ s/&$//s;
    if ($url =~ m|\?|s) {
        $gs = '&' . $gs;
    }
    else {
        $gs = '?' . $gs;
    }
    $url .= $gs;
    return $url;
}

1;
