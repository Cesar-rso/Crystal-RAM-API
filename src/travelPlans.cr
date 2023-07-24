require "kemal"
require "json"
require "http/client"
require "./models/*"
require "./config/*"

#Mensagem customizada para o erro 404
error 404 do
    "Travel not found!"
end

#Função utilizada pelos endpoints 4 e 6 para atualizar planos de viagem
def update_plan(id, stops, overwrite, env)
    plan = Travels.find!(id)
    if !plan
        env.response.status_code = 404
        raise Kemal::Exceptions::CustomException.new env
    end
    if overwrite
        plan.stops = arr_to_str(stops)
    else
        plan.stops += "," + arr_to_str(stops)
    end
    plan.save
    return plan
end

#Função para converter array em string sem os caracteres [] e sem whitespace
#feita pois a função built-in to_s não atende a necessidade desse projeto
def arr_to_str(arr : Array)
    str_ = ""
    arr.each{|x| str_ += x.to_s + ","}
    return str_.rchop
end

#Função para construir um json para o corpo da resposta
def json_response(id, stops, optimize, expand)
    
    #Requisição a API externa
    response = HTTP::Client.get "https://rickandmortyapi.com/api/location/#{stops}"
    body = JSON.parse(response.body)

    #Otimização da viagem
    if optimize.downcase == "true"
        stops = Array(Int32).new
        
        dimension = Hash(String, Hash(String, Array(Int32))).new
 
        body.as_a.each do |item|
            if dimension.has_key?(item["dimension"].to_s)
                dimension[item["dimension"].to_s][item["name"].to_s] = [item["id"].to_s.to_i, item["residents"].size]
            else
                dimension[item["dimension"].to_s] = {item["name"].to_s => [item["id"].to_s.to_i, item["residents"].size]}
            end
        end
    

        while !dimension.empty?
            dim_name = dimension.min_by {|k, v| v.size}[0]
            while !dimension[dim_name].empty?
                location = dimension[dim_name].min_by {|k, v| v[1]}
                stops << location[1][0]
                dimension[dim_name].delete(location[0])
            end

            dimension.delete(dim_name)
        end
    else
        #Paradas sem otimização
        stops = stops.split(",")

    end

    #Detalhamento da viagem
    if expand.downcase == "true"
        json_str = JSON.build do |json|
            json.object do
                json.field "id", id
                json.field "travel_stops" do
                    json.array do 
                        stops.each do |stop|
                            json.object do
                                json.field "id", stop.to_i
                                name = ""
                                type = ""
                                dimension = ""
                                body.as_a.each do |item|
                                    if item["id"].to_s.to_i == stop.to_i
                                        name = item["name"].to_s
                                        type = item["type"].to_s
                                        dimension = item["dimension"].to_s
                                        break
                                    end
                                end
                                json.field "name", name
                                json.field "type", type
                                json.field "dimension", dimension
                            end
                        end
                    end
                end
            end
        end
    else
        #Construção do json padrão, sem detalhamento
        json_str = JSON.build do |json|
            json.object do
                json.field "id", id
                json.field "travel_stops" do
                    json.array do 
                        stops.each do |stop|
                            json.number stop.to_i
                        end
                    end
                end
            end
        end
    end
    return json_str
end

#Endpoint 1 - Criar novo plano de viagem
post "/travel_plans" do |env|
    stops = env.params.json["travel_stops"].as(Array)
    
    str_stops = arr_to_str(stops)
    travel = Travels.create({stops: str_stops})
    json_str = json_response(travel.id, travel.stops, "false", "false")
    env.response.content_type = "application/json"
    env.response.status_code = 201
    json_str
end 

#Endpoint 2 - Obter todos os planos de viagem
get "/travel_plans" do |env|
    optimize = "false"
    expand = "false"
    if env.params.query.has_key?("optimize")
        optimize = env.params.query["optimize"]
    end
    if env.params.query.has_key?("expand")
        expand = env.params.query["expand"]
    end
    all_travels = Travels.all
    
    json_str = "["

    all_travels.each do |travel|

        json_str += json_response(travel.id, travel.stops, optimize, expand)
        json_str += ","

    end
    if json_str.size > 1
        json_str = json_str.rchop
    end
    json_str += "]"

    env.response.content_type = "application/json"
    env.response.status_code = 200
    json_str
end

#Endpoint 3 - Obter plano de viagem especifico
get "/travel_plans/:id" do |env|
    id = env.params.url["id"]
    optimize = "false"
    expand = "false"
    if env.params.query.has_key?("optimize")
        optimize = env.params.query["optimize"]
    end
    if env.params.query.has_key?("expand")
        expand = env.params.query["expand"]
    end
    plan = Travels.find!(id)
    if !plan
        env.response.status_code = 404
        raise Kemal::Exceptions::CustomException.new env
    else

        json_str = json_response(plan.id, plan.stops, optimize, expand)

        env.response.content_type = "application/json"
        env.response.status_code = 200
        json_str
    end
end

#Endpoint 4 - Atualizar plano de viagem
put "/travel_plans/:id" do |env|
    id = env.params.url["id"]
    stops = env.params.json["travel_stops"].as(Array)

    plan = update_plan(id, stops, true, env)
    json_str = json_response(plan.id, plan.stops, "false", "false")

    env.response.content_type = "application/json"
    env.response.status_code = 200
    json_str
end

#Endpoint 5 - Excluir plano de viagem
delete "/travel_plans/:id" do |env|
    id = env.params.url["id"]
    Travels.delete(id)
    env.response.status_code = 204
end

#Extra: Endpoint 6 - Adicionar paradas a plano de viagem existente 
#   Obs: Seria mais eficiente simplesmente incluir o parametro "overwrite" no endpoint 4,
#   para verificar se salva por cima ou anexa a lista de paradas ao plano existente.
#   Porém como o enunciado do problema diz especificamente para criar o endpoint "/travel_plans/:id/append"
#   criei o endpoint 6 para fins de avaliação
put "/travel_plans/:id/append" do |env|
    id = env.params.url["id"]
    stops = env.params.json["travel_stops"].as(Array)

    plan = update_plan(id, stops, false, env)
    json_str = json_response(plan.id, plan.stops, "false", "false")

    env.response.content_type = "application/json"
    env.response.status_code = 200
    json_str
end
