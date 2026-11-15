TERRAFORM ?= terraform
.DEFAULT_GOAL := tf-validate

export TF_VAR_digitalocean_token = $(DIGITALOCEAN_TOKEN)
export AWS_ACCESS_KEY_ID = $(SPACES_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY = $(SPACES_SECRET_ACCESS_KEY)

.PHONY: tf-bootstrap-init tf-bootstrap-plan tf-bootstrap-apply tf-backend-config tf-init tf-plan tf-apply tf-output tf-kubeconfig tf-fmt tf-validate tf-destroy

tf-bootstrap-init:
	$(TERRAFORM) -chdir=terraform/bootstrap init

tf-bootstrap-plan:
	$(TERRAFORM) -chdir=terraform/bootstrap plan -out=tfplan

tf-bootstrap-apply:
	$(TERRAFORM) -chdir=terraform/bootstrap apply tfplan

tf-backend-config:
	@config="$$($(TERRAFORM) -chdir=terraform/bootstrap output -raw backend_config)" && printf '%s\n' "$$config" > terraform/backend.hcl

tf-init:
	$(TERRAFORM) -chdir=terraform init -backend-config=backend.hcl

tf-plan:
	$(TERRAFORM) -chdir=terraform plan -out=tfplan

tf-apply:
	$(TERRAFORM) -chdir=terraform apply tfplan

tf-output:
	$(TERRAFORM) -chdir=terraform output

tf-kubeconfig:
	@mkdir -p .local
	@umask 077; $(TERRAFORM) -chdir=terraform output -raw kubeconfig > .local/kubeconfig.yaml
	@chmod 600 .local/kubeconfig.yaml

tf-fmt:
	$(TERRAFORM) fmt -recursive terraform

tf-validate:
	$(TERRAFORM) -chdir=terraform/bootstrap validate
	$(TERRAFORM) -chdir=terraform validate

tf-destroy:
	$(TERRAFORM) -chdir=terraform destroy
