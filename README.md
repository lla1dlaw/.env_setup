# Environment Setup & Dotfiles

This repository contains the automated infrastructure-as-code setup for my personal development environment. It utilizes Ansible for system provisioning, Chezmoi for dotfile management, and Bitwarden for secure secret injection.

## Prerequisites

Before bootstrapping a new machine, ensure you have the following configured in your Bitwarden vault:
* A Login item explicitly named **Ansible Vault**.
* The password field of this item must contain your Ansible Vault master password.

---

## 1. Initial Setup (New Machine)

To provision a completely fresh Linux system, run the following command. This script will install necessary prerequisites, download the Bitwarden CLI, authenticate you to retrieve the deployment secrets, clone this repository, and execute the Ansible playbook entirely headlessly.

```bash
curl -sL [https://raw.githubusercontent.com/lla1dlaw/.env_setup/main/scripts/bootstrap.sh](https://raw.githubusercontent.com/lla1dlaw/.env_setup/main/scripts/bootstrap.sh) | bash
