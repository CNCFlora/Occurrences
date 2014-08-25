
get '/families' do
    families=[]

    r = search("taxon","taxonomicStatus:\"accepted\"")
    r.each{|taxon|
        families.push taxon["family"].upcase
    }

    view :families, {:families=>families.uniq.sort}
end

get '/family/:family' do
    family = params[:family]
    species= search("taxon","family:\"#{family}\" AND taxonomicStatus:\"accepted\" 
                    AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
                    .sort {|t1,t2| t1["scientificName"] <=> t2["scientificName"] }
    view :family, {:species=>species,:family=>family}
end


get '/specie/:name' do
    query = "\"#{params[:name]}\""

    search("taxon","acceptedNameUsage:\"#{params[:name]}\"").each {|t|
        query << " OR \"#{t["scientificNameWithoutAuthorship"]}\""
    }

    redirect "#{settings.config[:base]}/search?q=#{URI.encode( query )}"
end

get '/specie/:name/:status' do

    query = ""

    #query << "("

    if params[:status] == 'validated' then
        #query << "validation.status:\"valid\" OR validation.status:\"invalid\""
    elsif params[:status] == 'reviewed' then
        #query << "georeferenceVerificationStatus:\"valid\" OR georeferenceVerificationStatus:\"nok\" OR georeferenceVerificationStatus:\"uncertain-locality\""
    elsif params[:status] == 'not_reviewed' then
        #query << "NOT georeferenceVerificationStatus:\"valid\" AND NOT georeferenceVerificationStatus:\"nok\" AND NOT georeferenceVerificationStatus:\"uncertain-locality\""
    elsif params[:status] == 'not_validated' then
        #query << "NOT validation.status:\"valid\" AND NOT validation.status:\"invalid\""
    end

    #query << ") AND "
    
    query << "(\"#{params[:name]}\""

    search("taxon","acceptedNameUsage:\"#{params[:name]}\"").each {|t|
        query << " OR \"#{t["scientificNameWithoutAuthorship"]}\""
    }

    query << ")"

    redirect "#{settings.config[:base]}/search?q=#{URI.encode( query )}"
end
