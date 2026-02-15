# ------------------- #
#       Cloud SQL     #  
# ------------------- #

authorized_ip = "89.210.41.207"
db_name = "mydatabase"
db_user = "myuser"
db_password = "mypassword"  

# ------------------- #
#       Cloud RUN     #  
# ------------------- #
service_name = "crowdfunding-api"
image = "europe-west1-docker.pkg.dev/tf-project-1763286414/crowdfunding-repo/nikos-kaparos/crowdfunding-backend:v.1.2.prod-b54729a"

# -------------------- #
#   Cloud Run Frontend #  
# -------------------- #
frontend-service_name = "crowdfunding-run-frontend"
frontend-image = "europe-west1-docker.pkg.dev/tf-project-1763286414/crowdfunding-repo/nikos-kaparos/crowdfunding-frontend:v.1.2.prod-b54729a"

