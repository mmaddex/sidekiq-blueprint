# A sample app to demo Sidekiq on Render
# Credits: https://github.com/mperham/sidekiq/blob/master/examples/sinkiq.rb
require 'sinatra'
require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'shrine'
require 'blurhash'

$redis = Redis.new

class PictureUploader < Shrine
    plugin :blurhash
end

class SinatraWorker
  include Sidekiq::Worker
  puts "SIDEKICK WORKER - #{ENV['RENDER_INSTANCE_ID']}"

  def perform(msg = "lulz you forgot a msg!")
    puts "SIDEKICK PERFORM - #{ENV['RENDER_INSTANCE_ID']}"
    $redis.lpush("sinkiq-example-messages", msg)
  end
end

get '/' do
  stats = Sidekiq::Stats.new
  @failed = stats.failed
  @processed = stats.processed
  @messages = $redis.lrange('sinkiq-example-messages', 0, -1)
  erb :index
end

post '/msg' do
  SinatraWorker.perform_async params[:msg]
  redirect to('/')
end

__END__

@@ layout
<html>
  <head>
    <title>Sinatra + Sidekiq</title>
    <body>
      <%= yield %>
    </body>
</html>

@@ index
  <h1>Sinatra + Sidekiq Example</h1>
  <h2>Failed: <%= @failed %></h2>
  <h2>Processed: <%= @processed %></h2>

  <form method="post" action="/msg">
    <input type="text" name="msg">
    <input type="submit" value="Add Message">
  </form>

  <a href="/">Refresh page</a>

  <h3>Messages</h3>
  <% @messages.each do |msg| %>
    <p><%= msg %></p>
  <% end %>
