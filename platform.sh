#!/bin/bash

required_ruby="2.0.0-p247"
required_bundle="Bundler version 1.3.5"
required_gem="2.0.3"

echo "required ruby   => $required_ruby"
echo "required bundle => $required_bundle"
echo "required gem    => $required_gem"
echo
echo "current ruby   => $(ruby --version)"
echo "current bundle => $(bundle --version)"
echo "current gem    => $(gem --version)"
echo
echo "If the current gem version is different from that required, try:"
echo "$ gem update --system $required_gem"
echo "$ bundle install"

