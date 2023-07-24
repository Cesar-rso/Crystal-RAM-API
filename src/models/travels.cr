require "jennifer"

class Travels < Jennifer::Model::Base
  
  mapping(
    id: Primary64,
    stops: { type: String, default: "" },
  )
end
  
  