pipeline{
    agent any
    stages{
        stage('Clone app project'){
            steps{
                sh '''
                rm -rf Crowdfunding
                git clone https://github.com/nikos-kaparos/Crowdfunding.git
                '''
            }
        }
    
        stage('Test backend and create result file'){
            steps{
                sh '''
                cd "$WORKSPACE/iac-pipeline"
                pwd
                dagger call backend-test --src $WORKSPACE/Crowdfunding \
                export --path $WORKSPACE/Crowdfunding/test-result
                '''
            }
        }

        stage('Scan Vulenrabilites'){
            steps{
              sh '''
              pwd
              dagger call trivy-scan-app-dir --src $WORKSPACE/Crowdfunding \
              export --path $WORKSPACE/trivy
              '''
            }
        }
    }   
}