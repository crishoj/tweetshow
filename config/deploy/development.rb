set :rails_env, "development"
role :web, "tweetshow.dev.jetment.net"
role :app, "tweetshow.dev.jetment.net"
role :db,  "tweetshow.dev.jetment.net", :primary => true

set :deploy_to, "/u/apps/#{application}.dev"
