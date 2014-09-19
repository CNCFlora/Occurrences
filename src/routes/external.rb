
get '/editor' do
    require_logged_in

    query = (params[:q] || "*").gsub("&quot","\"")
    occurrences = search("occurrence","#{query}")
    view :recline,{:occurrences=>occurrences,:query=>query}
end

get "/json" do
    require_logged_in

    query = (params[:q] || "*").gsub("&quot","\"")

    occurrences = []
    search("occurrence","#{query}").each {|occ|
        occ["decimalLatitude"] = occ["decimalLatitude"].to_f
        occ["decimalLongitude"] = occ["decimalLongitude"].to_f
        occurrences << occ;
    }

    r=""
    if params[:callback]
        r << params[:callback]
        r << "("
    end
    r << occurrences.to_json
    if params[:callback]
        r << ");"
    end
    r
end

post "/json" do
    require_logged_in

    data = JSON.parse(params[:data]) 
    keys = []
    data.each{|r| 
        keys << r['occurrenceID']
        keys << "#{ r['occurrenceID'] }.0"
    }
    r = http_post("#{settings.config[:couchdb]}/_all_docs",{:keys=>keys})
    docs = []

    data.each{ |occ|
        r["rows"].each {|row|
            if row["id"] == occ["occurrenceID"] || row["id"] == "#{occ["occurrenceID"]}.0"
                occ["_rev"] = row["value"]["rev"]
                occ["_id"] = row["id"]
                occ["metadata"]["modified"] = Time.now.to_i

                if occ["metadata"]["contributor"].nil? then
                  occ["metadata"]["contributor"] = "#{session[:user]['name']}"
                  occ["metadata"]["contact"] = "#{session[:user]['email']}"
                elsif !occ["metadata"]["contributor"].match(session[:user]['name']) then
                  occ["metadata"]["contributor"] = "#{session[:user]['name']} ; #{occ["metadata"]["contributor"]}"
                  occ["metadata"]["contact"] = "#{session[:user]['email']} ; #{occ["metadata"]["contact"]}"
                end

                docs << occ
            end
        }
    }

    r=http_post("#{settings.config[:couchdb]}/_bulk_docs",{"docs"=> docs});

    query = URI.encode(params[:q].gsub("&quot;","\""))
    redirect "#{settings.config[:base]}/search?q=#{query}"
end

