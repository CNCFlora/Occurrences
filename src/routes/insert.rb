
get '/insert' do
    data = JSON.parse(params[:data])
    count = data.length
    species = []

    data.each {|occ|
        species.push occ["scientificName"]
        occ[:_id] = occ["occurrenceID"]
        occ[:metadata] = {
            :type => "occurrence",
            :created => Time.now.to_i,
            :modified => Time.now.to_i
            :creator => session[:user][:name]
            :contributor => session[:user][:name]
            :contact => session[:user][:email]
        }
    }

    http_post("#{settings.couchdb}/#{settings.db}/_bulk_docs",{"docs"=> data});

    view :inserted, {:count=>count,:species=>species.uniq}
end

post '/insert' do
    data = JSON.parse(request.body.read.to_s)
    count = data.length
    species = []

    data.each {|occ|
        species.push occ["scientificName"]
        occ["_id"] = occ["occurrenceID"]
        occ[:metadata] = {
            :type => "occurrence",
            :created => Time.now.to_i,
            :modified => Time.now.to_i
            :creator => session[:user][:name]
            :contributor => session[:user][:name]
            :contact => session[:user][:email]
        }
    }

    http_post("#{settings.couchdb}/#{settings.db}/_bulk_docs",{"docs"=> data});

    view :inserted, {:count=>count,:species=>species.uniq}
end

