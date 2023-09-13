#!/bin/bash

result=${PWD##*/}          # to assign to a variable
result=${result:-/}        # to correct for the case where PWD=/

# Start a new tmux session in detached mode with a name
tmux new-session -d -s "$result"

# Split the window vertically (creating two vertical panes)
tmux split-window -h

# Select the first pane and split it horizontally
tmux select-pane -t 0
tmux split-window -v

# Select the second pane and split it horizontally
tmux select-pane -t 2
tmux split-window -v

# Send commands to each pane
tmux send-keys -t "$result":0.0 'fab start && fab sh' C-m
tmux send-keys -t "$result":0.1 'fab start && fab sh' C-m
tmux send-keys -t "$result":0.2 'npm run start' C-m
tmux send-keys -t "$result":0.3 'git status' C-m

# Attach to the session
tmux attach -t "$result"
