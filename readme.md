    
    terraform init

# edit resource

    we can edit resource in terraform.tfvars

    terraform plan
    terraform apply

# run terraform and inject var-file

    terraform plan -var-file="/mnt/d/work-github/tfvar-secret/terraform-rke-hardened.tfvars"
    terraform apply -var-file="/mnt/d/work-github/tfvar-secret/terraform-rke-hardened.tfvars"