package ECPDF::Component;
use base qw/ECPDF::BaseClass/;
use strict;
use warnings;

sub classDefinition {
    return {
        componentInitParams => '*'
    };
}


1;
