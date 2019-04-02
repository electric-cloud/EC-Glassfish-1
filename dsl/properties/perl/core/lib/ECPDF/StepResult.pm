package ECPDF::StepResult;

=head1 NAME

ECPDF::StepResult

=head1 DESCRIPTION

This class sets various output results of step run.

=head1 METHODS

=cut

use base qw/ECPDF::BaseClass/;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use ECPDF::StepResult::Action;
use ECPDF::Log;
use ECPDF::EF::OutputParameters;


sub classDefinition {
    return {
        context => 'ECPDF::Context',
        actions => '*',
        cache => '*'
    };
}


sub getCacheForAction {
    my ($self, $actionType, $name, $value) = @_;

    my $cache = $self->getCache();
    if ($cache->{$actionType} && $cache->{$actionType}->{$name}) {
        return $cache->{$actionType}->{$name};
    }
    return '';
}

sub setCacheForAction {
    my ($self, $actionType, $name, $value) = @_;

    logDebug("Parameters for set cache: '$actionType', '$name', '$value'");
    my $cache = $self->getCache();
    my $line = $value;
    if ($cache->{$actionType} && $cache->{$actionType}->{$name}) {
        $line = sprintf("%s\n%s", $line, $value);
    }

    $cache->{$actionType}->{$name} = $line;
    return $line;
}

=over

=item B<setJobStepOutcome>

Schedules setting of a job step outcome. Could be warning, success or an error.

%%%LANG=perl%%%
    $stepResult->setJobStepOutcome('warning');
%%%LANG%%%

=back

=cut

sub setJobStepOutcome {
    my ($self, $path, $outcome) = @_;

    # if (!$path || !$outcome) {
    #     croak "Path and outcome are mandatory for setOutcome function.\n";
    # }
    # If only one parameter has been provided, we're setting other parameters.
    if ($path && !$outcome) {
        $outcome = $path;
        $path = '/myJobStep/outcome';
    }
    if ($outcome !~ m/^(?:error|warning|success)$/s) {
        croak "Outcome is expected to be one of: error, warning, success. Got: $outcome\n";
    }
    my $action = ECPDF::StepResult::Action->new({
        actionType  => 'setJobOutcome',
        entityName  => $path,
        entityValue => $outcome
    });

    my $actions = $self->getActions();
    push @$actions, $action;
    return $self;

}


=over

=item B<setPipelineSummary>

Sets the summary of the current pipeline task.

Summaries of pipelien tasks are available on pipeline stage execution result under the "Summary" link.

Following code will set pipeline summary with name 'Procedure Exectuion Result:' to 'All tests are ok'

%%%LANG=perl%%%
    $stepResult->setPipelineSummary('Procedure Execution Result:', 'All tests are ok');
%%%LANG%%%

=back

=cut

sub setPipelineSummary {
    my ($self, $pipelineProperty, $pipelineSummary) = @_;

    if (!$pipelineProperty || !$pipelineSummary) {
        croak "pipelineProperty and pipelineSummary are mandatory.\n";
    }

    my $action = ECPDF::StepResult::Action->new({
        actionType  => 'setPipelineSummary',
        entityName  => '/myPipelineStageRuntime/ec_summary/' . $pipelineProperty,
        entityValue => $self->setCacheForAction('setPipelineSummary', $pipelineSummary)
    });

    my $actions = $self->getActions();
    push @$actions, $action;
    return $self;
}


=over

=item B<setJobStepSummary>

Sets the summary of the current B<job step>.

%%%LANG=perl%%%
    $stepResult->setJobStepSummary('All tests are ok in this step.');
%%%LANG%%%

=back

=cut

sub setJobStepSummary {
    my ($self, $summary) = @_;

    if (!$summary) {
        croak "Summary is mandatory in setJobStepSummary\n";
    }

    my $property = '/myJobStep/summary';
    my $action = ECPDF::StepResult::Action->new({
        actionType => 'setJobStepSummary',
        entityName => $property,
        entityValue => $self->setCacheForAction('setJobStepSummary', $property, $summary)
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    return $self;
}


=over

=item B<setJobSummary>

Sets the summary of the current B<job>.

%%%LANG=perl%%%
    $stepResult->setJobSummary('All tests are ok');
%%%LANG%%%

=back

=cut

sub setJobSummary {
    my ($self, $summary) = @_;

    if (!$summary) {
        croak "Summary is mandatory in setJobStepSummary\n";
    }

    my $property = '/myCall/summary';
    my $action = ECPDF::StepResult::Action->new({
        actionType => 'setJobSummary',
        entityName => $property,
        entityValue => $self->setCacheForAction('setJobSummary', $property, $summary)
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    return $self;
}


=over

=item B<setOutcomeProperty>

Sets the outcome property.

%%%LANG=perl%%%
    $stepResult->setOutcomeProperty('/myJob/buildNumber', '42');
%%%LANG%%%

=back

=cut


sub setOutcomeProperty {
    my ($self, $propertyPath, $propertyValue) = @_;

    if (!$propertyPath || !$propertyValue) {
        croak "PropertyPath and PropertyValue are mandatory";
    }

    my $action = ECPDF::StepResult::Action->new({
        actionType => 'setOutcomeProperty',
        entityName => $propertyPath,
        entityValue => $propertyValue
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    return $self;
}

sub setOutputParameter {
    my ($self, $name, $value) = @_;

    if (!$name || !$value) {
        croak "Parameter name and parameter value are mandatory when set output parameter is scheduled";
    }

    my $action = ECPDF::StepResult::Action->new({
        actionType => 'setOutputParameter',
        entityName => $name,
        entityValue => $self->setCacheForAction('setOutputParameter', $name, $value)
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    return $self;
}

=over

=item B<apply>

Applies scheduled changes without schedule cleanup in queue order: first scheduled, first executed.

%%%LANG=perl%%%
    $stepResult->apply();
%%%LANG%%%

=back

=cut

sub apply {
    my ($self) = @_;

    my $actions = $self->getActions();
    for my $action (@$actions) {
        if (!ref $action) {
            # TODO: Improve error message here.
            croak "Reference is expected";
        }
        if (ref $action ne 'ECPDF::StepResult::Action') {
            croak "ECPDF::StepResult::Action is expected. Got: ", ref $action;
        }

        my $currentAction = $action->getActionType();
        my $left = $action->getEntityName();
        my $right = $action->getEntityValue();
        my $ec = $self->getContext()->getEc();
        if ($currentAction eq 'setJobOutcome' || $currentAction eq 'setJobStepOutcome') {
            $ec->setProperty($left, $right);
        }
        # TODO: Refactor this if condition
        elsif ($currentAction eq 'setPipelineSummary' || $currentAction eq 'setOutcomeProperty' || $currentAction eq 'setJobSummary' || $currentAction eq 'setJobStepSummary') {
            $ec->setProperty($left, $right);
        }
        elsif ($currentAction eq 'setOutputParameter') {
            my $op = ECPDF::EF::OutputParameters->new({
                ec => $ec
            });
            $op->setOutputParameter($left, $right, {});
            # croak "Output parameters are not implemented yet for StepResult\n";
        }
        else {
            croak "Action $currentAction is not implemented yet\n";
        }
    }
    logTrace("Actions: ", Dumper $self->{actions});
    logTrace("Actions cache: ", Dumper $self->{cache});
    return $self;

}


=over

=item B<flush>

Flushes scheduled actions.

%%%LANG=perl%%%
    $stepResult->flush();
%%%LANG%%%

=back

=cut

sub flush {
    my ($self) = @_;

    my $actions = $self->getActions();
    # now we're copying an actions array because it is a reference.
    my @clonedActions = @$actions;
    $self->setActions([]);
    $self->setCache({});

    return \@clonedActions;
}


=over

=item B<applyAndFlush>

Executes the schedule queue and flushed it then.

%%%LANG=perl%%%
    $stepResult->applyAndFlush();
%%%LANG%%%

=back

=cut

sub applyAndFlush {
    my ($self) = @_;

    $self->apply();
    return $self->flush();
}

1;

