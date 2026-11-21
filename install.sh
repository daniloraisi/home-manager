#!/usr/bin/env bash
# Dotfiles dos GitHub Codespaces: o Codespaces clona este repositório e roda este script ao criar cada codespace
# (github.com → Settings → Codespaces → Dotfiles, com "Automatically install dotfiles").
#
# Faz no codespace o mesmo que o nix-hm.sh faz no WSL, usando o Nix que o devcontainer já traz:
# local.nix, AstroNvim, Home Manager (danilo@codespace) e o zsh como shell de login (gh codespace ssh).
#
# Fora de um codespace, ou num codespace sem Nix, não faz nada: o log de criação mostra o motivo e o codespace
# continua normal. O log fica em /workspaces/.codespaces/.persistedshare/creation.log.
set -euo pipefail

log() { printf '\n==> [dotfiles] %s\n' "$*"; }

if [ "${CODESPACES:-}" != "true" ]; then
  log "Fora de um Codespace: nada a fazer (no WSL, use o nix-hm.sh)."
  exit 0
fi

# Nix do devcontainer (feature ghcr.io/devcontainers/features/nix, de usuário único)
for profile in "$HOME/.nix-profile/etc/profile.d/nix.sh" /nix/var/nix/profiles/default/etc/profile.d/nix.sh; do
  # shellcheck disable=SC1090
  [ -f "$profile" ] && . "$profile" && break
done
if ! command -v nix >/dev/null 2>&1; then
  log "Este codespace não tem Nix: Home Manager e AstroNvim ficam de fora."
  exit 0
fi

HM_DIR="$HOME/.config/home-manager"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HM_VERSION="release-26.05"

log "Flakes"
mkdir -p "$HOME/.config/nix"
grep -qs 'experimental-features' "$HOME/.config/nix/nix.conf" ||
  echo "experimental-features = nix-command flakes" >>"$HOME/.config/nix/nix.conf"
nix flake --help >/dev/null

log "Configuração do Home Manager em $HM_DIR"
mkdir -p "$HOME/.config"
if [ ! -e "$HM_DIR" ]; then
  ln -s "$REPO_DIR" "$HM_DIR"
fi

# Usuário, home e identidade do git deste codespace. O home.nix fixa danilo e /home/danilo; aqui o usuário é o da
# imagem (vscode nas imagens dos devcontainers). O nome e o e-mail vêm do git, que o Codespaces configura com os dados
# da sua conta.
# Escapa \, " e ${ para caber numa string Nix (como o nix-hm.sh).
nix_str() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\${/\\${/g'; }
GIT_NAME="$(nix_str "$(git config --get user.name || echo 'Danilo Raisi')")"
GIT_EMAIL="$(nix_str "$(git config --get user.email || echo 'danilo@raisi.tech')")"
cat >"$HM_DIR/local.nix" <<NIX
{ lib, ... }:

{
  home.username = lib.mkForce "$USER";
  home.homeDirectory = lib.mkForce "$HOME";

  programs.git.settings.user = {
    name = "$GIT_NAME";
    email = "$GIT_EMAIL";
  };
}
NIX
# O flake só enxerga arquivos que o git conhece; o local.nix está no .gitignore.
git -C "$HM_DIR" add --intent-to-add --force local.nix

log "AstroNvim em ~/.astronvim"
if [ ! -d "$HOME/.astronvim" ]; then
  git clone --depth 1 https://github.com/AstroNvim/template "$HOME/.astronvim"
  rm -rf "$HOME/.astronvim/.git"
fi

log "Home Manager ($HM_VERSION, danilo@codespace)"
nix run "home-manager/$HM_VERSION" -- -b backup switch --flake "$HM_DIR#danilo@codespace"

log "zsh como shell de login"
ZSH_BIN="$(command -v zsh || true)"
[ -x /usr/bin/zsh ] && ZSH_BIN=/usr/bin/zsh
[ -z "$ZSH_BIN" ] && ZSH_BIN="$HOME/.nix-profile/bin/zsh"
if [ -x "$ZSH_BIN" ] && command -v sudo >/dev/null 2>&1; then
  grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$ZSH_BIN" "$USER"
else
  log "Sem zsh ou sem sudo: o shell de login continua o mesmo."
fi

log "Pronto. Entre com: gh codespace ssh"
