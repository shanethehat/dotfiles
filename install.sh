#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
###########################

DEFAULT_EMAIL="shane.auckland@gmail.com"
DEFAULT_GITHUBUSER="shanethehat"
DEFAULT_NAME="Shane Auckland"
DEFAULT_USERNAME="shanethehat"


# include my library helpers for colorized echo and require_brew, etc
source ./lib.sh

# make a backup directory for overwritten dotfiles
mkdir -p ~/.dotfiles_backup
# ensure ~/.gitshots exists
mkdir -p ~/.gitshots

bot "Hi. I'm going to make your OSX system better. But first, I need to configure this project based on your info so you don't check in files to github"

fullname="$DEFAULT_NAME"

email=`dscl . -read /Users/$(whoami)  | grep EMailAddress | sed "s/EMailAddress: //"`
if [[ ! $email ]];then
  response='n'
else
  echo -e "The best I can make out, your email address is $COL_YELLOW$email$COL_RESET"
  read -r -p "Is this correct? [Y|n] " response
fi

if [[ $response =~ ^(no|n|N) ]];then
  read -r -p "What is your email? [$DEFAULT_EMAIL] " email
  if [[ ! $email ]];then
    email=$DEFAULT_EMAIL
  fi
fi

grep "user = $DEFAULT_GITHUBUSER" .gitconfig
if [[ $? = 0 ]]; then
    read -r -p "What is your github.com username? [$DEFAULT_GITHUBUSER]" githubuser
fi
if [[ ! $githubuser ]];then
  githubuser=$DEFAULT_GITHUBUSER
fi

running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

# test if gnu-sed or osx sed

sed -i 's/'$DEFAULT_EMAIL'/'$email'/' .gitconfig > /dev/null 2>&1 | true
if [[ ${PIPESTATUS[0]} != 0 ]]; then
  echo
  running "looks like you are using OSX sed rather than gnu-sed, accommodating"
  sed -i '' 's/'$DEFAULT_EMAIL'/'$email'/' .gitconfig;
  sed -i '' 's/'$DEFAULT_GITHUBUSER'/'$githubuser'/' .gitconfig;
  sed -i '' 's/'$DEFAULT_USERNAME'/'$(whoami)'/g' .zshrc;ok
else
  echo
  bot "looks like you are already using gnu-sed. woot!"
  sed -i 's/'$DEFAULT_GITHUBUSER'/'$githubuser'/' .gitconfig;
  sed -i 's/'$DEFAULT_USERNAME'/'$(whoami)'/g' .zshrc;ok
fi

bot "make sure we're in the home directory"
pushd ~ > /dev/null 2>&1

bot "creating symlinks for shell agnostic project dotfiles..."

symlinkifne .gemrc
symlinkifne .gitconfig
symlinkifne .gitignore
symlinkifne .tmux.conf
symlinkifne .vim
symlinkifne .vimrc

bot "Create iterm profile symlink"

ITERM_PROFILE_PATH="~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm_profile"
if [[ -L "$ITERM_PROFILE_PATH" ]]; then
  # it's already a simlink (could have come from this project)
  echo -en '\tsimlink exists, skipped\t';ok
  return
else
  ln -s ~/.dotfiles/iterm_profile "$ITERM_PROFILE_PATH"
fi

bot "set iterm profile"
echo -e "\033]50;SetProfile=ShaneProfile\a"

bot "leave the home directory"
popd > /dev/null 2>&1

./osx.sh

bot "now it's time to set up your shell"
read -r -p "Which shell would you like to use? [FISH|zsh]" response
if [[ $response =~ ^(zsh|ZSH)$ ]]; then
  ./install-zsh.sh
else
  ./install-fish.sh
fi

bot "Woot! All done. Restart your terminal app."
