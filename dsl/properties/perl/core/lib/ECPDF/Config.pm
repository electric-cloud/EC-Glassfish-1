=head1 NAME

ECPDF::Config

=head1 DESCRIPTION

This class has the same API as L<ECPDF::StepParameters>.

See L<ECPDF::StepParameters> for details.

=cut

package ECPDF::Config;
use ElectricCommander;

use base qw/ECPDF::StepParameters/;
use strict;
use warnings;
use Carp;

# sub classDefinition {
#     return {
#         parametersList => '*',
#         parameters => '*',
#         ec => '*'
#     };
# }

# sub parameterExists {};
# sub getParameter {};
# sub setParameter {};
# sub setCredential {};
# sub getCredential {};



1;
