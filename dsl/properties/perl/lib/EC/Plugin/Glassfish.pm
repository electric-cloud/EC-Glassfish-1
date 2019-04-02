package EC::Plugin::Glassfish;
use strict;
use warnings;
use base qw/ECPDF/;
use Data::Dumper;
use File::Temp qw(tempfile);

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName    => '@PLUGIN_KEY@',
        pluginVersion => '@PLUGIN_VERSION@',
        configFields  => ['config'],
        configLocations => ['ec_plugin_cfgs']
    };
}


sub authCommand {
    my ($self) = @_;

    my $context = $self->newContext();
    my $configValues = $context->getConfigValues();
    # Step 1 and 2. Loading component and creating CLI executor with working directory of current workspace.
    my $cli = ECPDF::ComponentManager->loadComponent('ECPDF::Component::CLI', {
      workingDirectory => $ENV{COMMANDER_WORKSPACE}
    });
    my $cliPath = $configValues->getParameter('cliPath');
    my $command = $cli->newCommand($cliPath);
    my $cred = $configValues->getParameter('credential');
    if ($cred) {
        my $username = $cred->getUserName();
        my $password = $cred->getSecretValue();
        my ($fh, $filename) = tempfile();
        print $fh "AS_ADMIN_PASSWORD=$password";
        close $fh;
        $command->addArguments('--user');
        $command->addArguments($username);
        $command->addArguments('--passwordfile');
        $command->addArguments($filename);
    }

    return ($cli, $command);
}

sub deploy {
    my ($self) = @_;

    my $context = $self->newContext();
    my $params = $context->getStepParameters();
    my $configValues = $context->getConfigValues();


    my $appPath = $params->getParameter('applicationPath');
    my ($cli, $command) = $self->authCommand();
    $command->addArguments("deploy", $appPath);
    print "Command to run: ". $command->renderCommand() . "\n";

    # Step 4. Executing a command
    my $res = $cli->runCommand($command);
    $self->processRes($res);
}



sub undeploy {
    my ($self) = @_;
    my $context = $self->newContext();
    my $params = $context->getStepParameters();
    my $configValues = $context->getConfigValues();

    my $appName = $params->getParameter('applicationName');
    my ($cli, $command) = $self->authCommand();
    $command->addArguments("undeploy", $appName);
    print "Command to run: ". $command->renderCommand() . "\n";

    # Step 4. Executing a command
    my $res = $cli->runCommand($command);
    $self->processRes($res);
}
## === step ends ===


sub processRes {
    my ($self, $res) = @_;

    print "STDOUT: " . $res->getStdout();
    print "STDERR: " . $res->getStderr();
    my $code = $res->getCode();
    my $stepResult = $self->newContext()->newStepResult();
    if ($code != 0) {
        $stepResult->setJobStepOutcome('error');
        $stepResult->setJobStepSummary($res->getStderr());
    }
    else {
        $stepResult->setJobStepSummary($res->getStdout());
    }
    $stepResult->apply();
}

1;
