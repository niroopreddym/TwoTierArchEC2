pipeline {
   agent any
   environment {
      Access_Key = credentials('Access_Key')
      Secret_Key = credentials('Secret_Key')
   }
   stages {
      stage("build"){
         steps{
            echo 'build'
         }
      }

      stage("deploy"){
         steps{
            script {
               sh '(sed -i -e "s|{Secret_Key}|${{environment.Secret_Key}}|g; s|{Access_Key}|${{environment.Access_Key}}|g" .github/workflows/scripts/cfn.json)'
               sh '(cat .github/workflows/scripts/cfn.json)'
               sh '(cd ${WORKSPACE};chmod 777 ./Jenkins/deploy.sh;  ./Jenkins/deploy.sh )'     
            }
         }
      }
   }
}