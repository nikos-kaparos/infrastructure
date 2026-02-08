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
              cd "$WORKSPACE/iac-pipeline"
              pwd
              dagger call trivy-scan-app-dir --src $WORKSPACE/Crowdfunding \
              export --path $WORKSPACE/Crowdfunding/trivy
              '''
            }
        }

        stage('Filtering JSON Vulenrabilites'){
            steps{
              sh '''
              cd "$WORKSPACE/iac-pipeline"
              pwd
              dagger call filtering-json-report --report-dir $WORKSPACE/Crowdfunding/trivy \
              export --path $WORKSPACE/Crowdfunding/trivy/filtered
              '''
            }
        }

        stage('Vulnerabilities Check'){
            steps{
              sh'''
              cd "$WORKSPACE/iac-pipeline"
              pwd
              dagger call vulnerabilities-check --summary_dir $WORKSPACE/Crowdfunding/trivy/filtered
              '''
            }
        }
    }   
}