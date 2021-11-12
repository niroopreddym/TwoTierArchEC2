pipeline {
   agent any
   stages {
      stage("build"){
         steps{
            echo 'build'
         }
      }

      stage("deploy"){
         steps{
            script {
               sh '(cd ${WORKSPACE};chmod 777 ./Jenkins/deploy.sh;  ./Jenkins/deploy.sh )'     
            }
         }
      }
   }
}