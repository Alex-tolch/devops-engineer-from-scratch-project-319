TERRAFORM ?= terraform
KUBECTL ?= kubectl
.DEFAULT_GOAL := tf-validate

export TF_VAR_digitalocean_token = $(DIGITALOCEAN_TOKEN)
export AWS_ACCESS_KEY_ID = $(SPACES_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY = $(SPACES_SECRET_ACCESS_KEY)

.PHONY: tf-bootstrap-init tf-bootstrap-plan tf-bootstrap-apply tf-backend-config tf-init tf-plan tf-apply tf-output tf-kubeconfig tf-fmt tf-validate tf-destroy
.PHONY: k8s-apply k8s-status k8s-port-forward k8s-check

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

k8s-apply:
	@test -f k8s/secret.yaml || { printf '%s\n' 'Copy k8s/secret.yaml.example to k8s/secret.yaml and fill in the application credentials.'; exit 1; }
	$(KUBECTL) apply -f k8s/namespace.yaml
	$(KUBECTL) apply -f k8s/configmap.yaml -f k8s/secret.yaml
	$(KUBECTL) apply -f k8s/deployment.yaml -f k8s/service.yaml
	$(KUBECTL) -n bulletin-board rollout status deployment/bulletin-board --timeout=300s

k8s-status:
	$(KUBECTL) -n bulletin-board get deployments,pods,services

k8s-port-forward:
	$(KUBECTL) -n bulletin-board port-forward service/bulletin-board 8080:80

k8s-check:
	curl --fail http://127.0.0.1:8080/ --output /dev/null
	curl --fail http://127.0.0.1:8080/api/bulletins
