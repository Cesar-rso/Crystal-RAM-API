require "jennifer"
require "jennifer_sqlite3_adapter"

Jennifer::Config.configure do |conf|
    conf.adapter = "sqlite3"
    conf.host = "."
    conf.db = "travels.db"
end