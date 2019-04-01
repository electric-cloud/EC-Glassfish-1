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

sub deploy {
    my ($pluginObject) = @_;

    my $context = $pluginObject->newContext();
    my $params = $context->getStepParameters();

    my $configValues = $context->getConfigValues();

    my $cred = $configValues->getParameter('credential');

    my $cliPath = $configValues->{cliPath};
    my $appPath = $params->getParameter('applicationPath');
    # Step 1 and 2. Loading component and creating CLI executor with working directory of current workspace.
    my $cli = ECPDF::ComponentManager->loadComponent('ECPDF::Component::CLI', {
      workingDirectory => $ENV{COMMANDER_WORKSPACE}
    });
    if ($cred) {
        my $username = $cred->getUserName();
        my $password = $cred->getSecretValue();
        my ($fh, $filename) = tempfile();
        print $fh "AS_ADMIN_PASSWORD=$password";
        close $fh;
        $cli->addArguments('--user');
        $cli->addArguments($username);
        $cli->addArguments('--passwordfile');
        $cli->addArguments($filename);
    }
    $cli->addArguments($appPath);
    print "Command to run: ". $cli->renderCommand() . "\n";

    # bin/asadmin --user admin --passwordfile password undeploy hello-world


    # Step 3. Creating new command with ls as shell and -la as parameter.
    my $command = $cli->newCommand($cliPath, [$appPath]);
    # Step 4. Executing a command
    my $res = $cli->runCommand($command);

    # $command->addArguments('-lah');
    # Step 5. Processing a response.
    print "STDOUT: " . $res->getStdout();


    my $stepResult = $context->newStepResult();
    print "Created stepresult\n";
    $stepResult->setJobStepOutcome('warning');
    print "Set stepResult\n";

    $stepResult->setJobSummary("See, this is a whole job summary");
    $stepResult->setJobStepSummary('And this is a job step summary');

    $stepResult->apply();
}
sub undeploy {
    my ($pluginObject) = @_;
    my $context = $pluginObject->newContext();
    print "Current context is: ", $context->getRunContext(), "\n";
    my $params = $context->getStepParameters();
    print Dumper $params;

    my $configValues = $context->getConfigValues();
    print Dumper $configValues;

    my $stepResult = $context->newStepResult();
    print "Created stepresult\n";
    $stepResult->setJobStepOutcome('warning');
    print "Set stepResult\n";

    $stepResult->setJobSummary("See, this is a whole job summary");
    $stepResult->setJobStepSummary('And this is a job step summary');

    $stepResult->apply();
}
## === step ends ===


1;
