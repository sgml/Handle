#!/bin/bash

# Unpack secrets; -C ensures they unpack *in* the .travis directory
tar xvf .travis/secrets.tar -C .travis

# Setup SSH agent:
eval "$(ssh-agent -s)" #start the ssh agent
chmod 600 .travis/build-key.pem
ssh-add .travis/build-key.pem

# Setup git defaults:
git config --global user.email "gilbert@pellegrom.me"
git config --global user.name "Gilbert Pellegrom"

# Add SSH-based remote to GitHub repo:
git remote add handle git@github.com:gilbitron/Handle.git
git fetch handle

# Get box and build PHAR
wget https://box-project.github.io/box2/manifest.json
BOX_URL=$(php bin/parse-manifest.php manifest.json)
rm manifest.json
wget -O box.phar ${BOX_URL}
chmod 755 box.phar
./box.phar build -vv
# Without the following step, we cannot checkout the gh-pages branch due to
# file conflicts:
mv handle.phar handle.phar.tmp

# Checkout gh-pages and add PHAR file and version:
git checkout -b gh-pages handle/gh-pages
mv handle.phar.tmp handle.phar
sha1sum handle.phar > handle.phar.version
git add handle.phar handle.phar.version

# Create download bundle
tar -zcvf handle.tar.gz handle.phar handle.phar.pubkey
git add handle.tar.gz

# Commit and push:
git commit -m 'Rebuilt phar'
git push handle gh-pages:gh-pages