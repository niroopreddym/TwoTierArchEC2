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
               sh '(cd ${WORKSPACE}; ./Jenkins/deploy.sh )'     
            }
         }
      }
   }
}