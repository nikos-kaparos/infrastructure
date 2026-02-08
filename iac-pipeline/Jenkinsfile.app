pipeline{
    agent any
    stages{
        stage('Clone app project'){
            steps{
                sh 'git clone https://github.com/nikos-kaparos/Crowdfunding.git'
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
    }   
}






























dagger call tofu-init \
  --src=/home/tandalam/finalProject/iac/gcloud \
  --gcp-paas=/home/tandalam/finalProject/iac/gcp-paas \
  --infracost-api-key=env:INFRACOST_API_KEY \
  --ssh-private-key=env:SSH_PRIVATE_KEY \
  --ssh-public-key=env:SSH_PUBLIC_KEY \
  --gcp-sa-key=env:GCP_CREDENTIALS \
  --output ../output2


dagger call backend-test --src /home/tandalam/Ds/Crowdfunding export --path /home/tandalam/Ds/Crowdfunding/test-resutl

dagger call trivy-scan-app-dir \
  --src /home/tandalam/Ds/Crowdfunding \
  export --path /home/tandalam/Ds/Crowdfunding/trivy


  dagger call filtering-json-report \                                                                                                                                                               
  export --path /home/tandalam/Ds/Crowdfunding/trivy/test2

  dagger call vulnerabilities-check --summary_dir /home/tandalam/Ds/Crowdfunding/trivy/test2      



  dagger call build-image \                                                                                            ─╯
  --src /home/tandalam/Ds/Crowdfunding/backend \
  --image-name ghcr.io/nikos-kaparos/crowdfunding-backend \
  --tag test.5.vul.packages.gArti \
  --github_username env:GITHUB_USERNAME \
  --github_token env:GITHUB_TOKEN \
  --gar-username env:GAR_USERNAME \
  --gar-password env:GAR_PASSWORD













dagger call tofu-init \
  --src=/home/tandalam/finalProject/iac/gcloud \
  --gcp-paas=/home/tandalam/finalProject/iac/gcp-paas \
  --infracost-api-key=env:INFRACOST_API_KEY \
  --ssh-private-key=env:SSH_PRIVATE_KEY \
  --ssh-public-key=env:SSH_PUBLIC_KEY \
  --gcp-sa-key=env:GCP_CREDENTIALS \
  --output ../output2


dagger call backend-test --src /home/tandalam/Ds/Crowdfunding export --path /home/tandalam/Ds/Crowdfunding/test-resutl

dagger call trivy-scan-app-dir \
  --src /home/tandalam/Ds/Crowdfunding \
  export --path /home/tandalam/Ds/Crowdfunding/trivy


  dagger call filtering-json-report \                                                                                                                                                               
  export --path /home/tandalam/Ds/Crowdfunding/trivy/test2

  dagger call vulnerabilities-check --summary_dir /home/tandalam/Ds/Crowdfunding/trivy/test2      



  dagger call build-image \                                                                                            ─╯
  --src /home/tandalam/Ds/Crowdfunding/backend \
  --image-name ghcr.io/nikos-kaparos/crowdfunding-backend \
  --tag test.5.vul.packages.gArti \
  --github_username env:GITHUB_USERNAME \
  --github_token env:GITHUB_TOKEN \
  --gar-username env:GAR_USERNAME \
  --gar-password env:GAR_PASSWORD