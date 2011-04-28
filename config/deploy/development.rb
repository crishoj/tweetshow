set :rails_env, "development"
role :web, "sweetshow.dev.jetment.net"
role :app, "sweetshow.dev.jetment.net"
role :db,  "sweetshow.dev.jetment.net", :primary => true

set :deploy_to, "/u/apps/#{application}.dev"
