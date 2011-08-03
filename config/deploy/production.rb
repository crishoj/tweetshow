set :rails_env, "production"
role :web, "tweetshow.nu"
role :app, "tweetshow.nu"
role :db,  "tweetshow.nu", :primary => true

set :deploy_to, "/u/apps/#{application}.nu"
