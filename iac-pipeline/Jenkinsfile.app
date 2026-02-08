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

        stage('Build & Check Backend'){
            steps{
                withCredentials([
                    file(credentialsId: 'gcp-api-key', variable: 'GCP_KEY_FILE')
                    string(credentialsId: 'GITHUB_USERNAME', variable: 'GITHUB_USERNAME'),
                    string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN')
                ]){        
                    def gcpKeyContent = readFile(env.GCP_KEY_FILE)

                    sh'''
                    cd "$WORKSPACE/iac-pipeline"
                    pwd

                    # Export credentials ως environment variables
                    export GAR_USERNAME='_json_key'
                    export GAR_PASSWORD='${gcpKeyContent}'

                    daggerc call build-image 
                    --src $WORKSPACE/Crowdfunding/backend \
                    --image-name ghcr.io/nikos-kaparos/crowdfunding-backend \
                    --version v1.0.2 \
                    --github-username env:GITHUB_USERNAME \
                    --github-token env:GITHUB_TOKEN \
                    --gar-username env:GAR_USERNAME \
                    --gar-password env:GAR_PASSWORD
                    '''
                }       
            }
        }
    }   
}