// This procedure.dsl was generated automatically
// It will not be updated upon regeneration
// Additional code may be a added here
procedure 'Deploy', description: 'Deploys an application to Glassfish', {

    step 'Deploy', {
        description = ''
        command = new File("dsl/procedures/Deploy/steps/Deploy.pl").text
        shell = 'ec-perl'
        
        
        
    }
    
    formalOutputParameter 'deployed',
        description: 'JSON representation of the deployed application'
    

}
