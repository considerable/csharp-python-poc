PROJECT = src/HelloApiFunction
TERRAFORM_DIR = terraform

.PHONY: build test run clean pipeline-log tf-init tf-plan tf-apply tf-destroy hosting-stack-up hosting-stack-down hosting-stack-plan hosting-stack-apply hosting-stack-destroy

build:
	dotnet restore $(PROJECT)
	dotnet build $(PROJECT) --configuration Release --no-restore

test:
	dotnet test $(PROJECT) --configuration Release --no-build

run:
	dotnet run --project $(PROJECT)

tf-init:
	cd $(TERRAFORM_DIR) && terraform init

tf-plan:
	cd $(TERRAFORM_DIR) && terraform plan

tf-apply:
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

tf-destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

hosting-stack-plan: tf-plan
hosting-stack-apply: tf-apply
hosting-stack-destroy: tf-destroy
hosting-stack-up: tf-init tf-apply
hosting-stack-down: tf-destroy

pipeline-log:
	@./scripts/get-pipeline-log.sh

clean:
	rm -rf $(PROJECT)/bin $(PROJECT)/obj $(PROJECT)/publish .pipeline

