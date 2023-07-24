require "./src/travelPlans.cr"
require "kemal"

class Settings
  class_property host : String = "localhost", port = 3000
end

VERSION = "0.1.0"

Kemal.run

# Desenvolvido por: César Rodrigues de Oliveira
#           emails: cesar.rso@hotmail.com - cesarrodriguesdeoliveira@yahoo.com.br