#!/package/host/localhost/bash-4/bin/bash

export HOME=/home/weasel
. $HOME/.bash_profile

# Get into the project directory and start the Rails runner
cd $HOME/game
exec rails r -e production "Action.incomplete.to_be_completed.each do |action| action.perform! end"