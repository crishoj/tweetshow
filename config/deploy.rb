set :application, "tweetshow"
set :repository,  "git@github.com:crishoj/tweetshow.git"

set :scm, :git
set :branch, "master"

set :user, "deployer"  # The server's user for deploys
set :deploy_via, :remote_cache

set :default_stage, "development"
set :stages, %w(production development)
require 'capistrano/ext/multistage'

default_run_options[:pty] = true
