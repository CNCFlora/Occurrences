
get '/families' do
    families=[]

    r = search(settings.db,"metadata.type=\"taxon\"")
    r.each{|taxon|
        families.push taxon["family"]
    }

    view :families, {:families=>families.uniq.sort}
end

get '/family/:family' do
    family = params[:family]
    species= search(settings.db,"family:\"#{family}\" AND taxomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
                    .sort {|t1,t2| t1["scientificName"] <=> t2["scientificName"] }
    view :family, {:species=>species,:family=>family}
end


get '/specie/:name' do
    query = "\"#{params[:name]}\""

    search(settings.db,"acceptedNameUsage:\"#{params[:name]}\"").each {|t|
        query << " OR \"#{t["scientificName"]}\""
    }

    redirect "#{settings.config[:base]}/search?q=#{query}"
end
