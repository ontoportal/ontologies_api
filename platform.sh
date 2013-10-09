#!/bin/bash

required_ruby="2.0.0-p247"
required_bundle="Bundler version 1.3.5"
required_gem="2.0.3"

if which rbenv > /dev/null; then
    echo
    echo "###########################################################################"
    echo "### RBENV"
    echo "rbenv         => $(which rbenv)"
    echo "rbenv version => $(rbenv version)"
    echo "rbenv ruby    => $(rbenv which ruby)"
    echo "rbenv gem     => $(rbenv which gem)"
    echo "rbenv bundle  => $(rbenv which bundle)"
fi
echo
echo "###########################################################################"
echo "### Current shell (could be using rbenv)"
echo "which ruby       => $(which ruby)"
echo "ruby --version   => $(ruby --version)"
echo "which gem        => $(which gem)"
echo "gem --version    => $(gem --version)"
echo "\$GEM_HOME        => $GEM_HOME"
echo "which bundle     => $(which bundle)"
echo "bundle --version => $(bundle --version)"
echo "\$BUNDLE_PATH     => $BUNDLE_PATH"
echo
echo "###########################################################################"
echo "### Required"
echo "ruby --version   => $required_ruby"
echo "bundle --version => $required_bundle"
echo "gem --version    => $required_gem"
echo
echo "# Note: if the current gem version is different from that required, try:"
echo "$ gem update --system $required_gem"
echo "$ bundle install"
echo

