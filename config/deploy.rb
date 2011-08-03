set :application, "tweetshow"
set :repository,  "git@github.com:crishoj/tweetshow.git"

set :scm, :git
set :branch, "master"

set :user, "deployer"  # The server's user for deploys
set :deploy_via, :remote_cache

set :default_stage, "development"
set :stages, %w(production development)

# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
set :rvm_ruby_string, '1.9.2'

require 'capistrano/ext/multistage'
require 'bundler/capistrano'

default_run_options[:pty] = true
