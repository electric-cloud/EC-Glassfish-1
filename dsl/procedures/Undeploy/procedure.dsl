// This procedure.dsl was generated automatically
// It will not be updated upon regeneration
// Additional code may be a added here
procedure 'Undeploy', description: 'Undeploys an application from Glassfish', {

    step 'Undeploy', {
        description = ''
        command = new File("dsl/procedures/Undeploy/steps/Undeploy.pl").text
        shell = 'ec-perl'
        
        
        
    }
    

}
