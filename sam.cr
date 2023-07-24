require "./src/config/*"
require "jennifer"
require "jennifer_sqlite3_adapter" 
require "sam"
require "./db/migrations/*"
load_dependencies "jennifer"

# Here you can define your tasks
# desc "with description to be used by help command"
# task "test" do
#   puts "ping"
# end

Sam.help
