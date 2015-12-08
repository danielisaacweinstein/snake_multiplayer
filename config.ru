require './app'
require './middlewares/multisnake_server'

use Multisnake::MultisnakeServer

run Multisnake::App
