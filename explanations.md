# DOCKER RUN

## Command
docker run

## Purpose
Creates and starts a new container from an image.

## Common Usage
```bash
docker run --name <name> -d -p <host-port>:<container-port> <image>
```

## Notes
- Use `--name` to assign a stable container name.
- Use `-d` to run the container in detached mode.
- Use `-p` to publish container ports to the host.
- Use `--rm` for temporary containers that should be removed after exit.

# KUBECTL APPLY

## Command
kubectl apply -f <file>

## Purpose
Creates or updates Kubernetes resources from a YAML manifest.

## Common Usage
```bash
kubectl apply -f deployment.yaml
kubectl apply -f .
```

## Notes
- `apply` is usually preferred for declarative Kubernetes workflows.
- Re-running the same command updates the existing resource instead of blindly recreating it.
- Use `kubectl diff -f <file>` before applying when you want to preview changes.

# TERRAFORM INIT

## Command
terraform init

## Purpose
Initializes a Terraform working directory by downloading providers, modules, and backend configuration.

## Common Usage
```bash
terraform init
terraform init -migrate-state
```

## Notes
- Run this before `terraform plan` or `terraform apply`.
- Re-run it after changing providers, modules, or backend settings.
- Use `-migrate-state` when changing backend configuration and moving existing state.

# ANSIBLE PLAYBOOK

## Command
ansible-playbook <playbook>.yml -i <inventory>

## Purpose
Runs an Ansible playbook against hosts from an inventory file.

## Common Usage
```bash
ansible-playbook site.yml -i inventory.yml
ansible-playbook site.yml -i inventory.yml --syntax-check
```

## Notes
- Use `--syntax-check` before running a new or edited playbook.
- Use `--become` inside plays or tasks when privileged operations are needed.
- Keep inventory, variables, and playbooks separate for reusable automation.

# GIT RESET

## Command
git reset

## Purpose
Moves Git history or staging state depending on the selected reset mode.

## Common Usage
```bash
git reset --soft HEAD~1
git reset --mixed HEAD~1
git restore --staged <file>
```

## Notes
- `--soft` keeps changes staged.
- `--mixed` keeps changes in the working tree but unstages them.
- Prefer `git revert <commit>` for shared branch history.
