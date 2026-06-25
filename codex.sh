#!/bin/bash

curl -x http://127.0.0.1:8118 -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
sudo npm install -g @openai/codex