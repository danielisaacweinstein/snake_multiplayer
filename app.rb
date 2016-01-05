require 'sinatra/base'

module Multisnake
  class App < Sinatra::Base

    # Optional room parameter when supporting multiple games at once.
    get "/?:room" do
      erb :"index.html"
    end

    get "/assets/js/application.js" do
      content_type :js
      @scheme = ENV['RACK_ENV'] == "production" ? "wss://" : "ws://"
      erb :"application.js"
    end
  end
end
