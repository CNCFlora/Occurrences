
get '/search' do
    query = (params[:q] || "scientificName:'Aphelandra longiflora'").gsub("&quot","\"")
    occurrences = search("occurrence",query)

    valid=0
    invalid=0
    reviewed=0
    validated=0
    not_reviewed=0
    not_validated=0
    eoo="soon"
    aoo="soon"
    i=0

    occurrences.each{ |occ| 
        occ[:json] = JSON.dump(occ) 
        occ[:occurrenceID2] = i

        if occ.has_key?("decimalLatitude")
            if occ["decimalLatitude"] == 0.0
                occ.delete("decimalLatitude")
            end
        end
        if occ.has_key?("decimalLongitude")
            if occ["decimalLongitude"] == 0.0
                occ.delete("decimalLongitude")
            end
        end

        if occ.has_key?("georeferenceVerificationStatus") 
            reviewed += 1
        else
            not_reviewed +1 
        end

        if occ.has_key?("validation")
            if occ["validation"].has_key?("status")
                if occ["validation"]["status"] === 'valid'
                    validated += 1
                    valid += 1
                    occ["valid"] = true
                    occ["invalid"] = false 
                elsif occ["validation"]["status"] === 'invalid'
                    validated += 1
                    invalid += 1
                    occ["valid"] = false
                    occ["invalid"] = true
                else 
                    not_validated += 1
                end
            end
            if occ["validation"].has_key?("reason")
                occ["reason-#{occ["validation"]["reason"].gsub(" ","-")}".to_sym] = true
            end
            if occ.has_key?("occurrenceStatus")
                occ["presence-#{occ["occurrenceStatus"]}".to_sym] = true
            end
        end

        i += 1
    }
    total = i

    data = {
        :result=>occurrences,
        :query=>query,
        :stats=>{
            :eoo=>eoo,
            :aoo=>aoo,
            :total=>total,
            :valid=>valid,
            :invalid=>invalid,
            :reviewed=>reviewed,
            :validated=>validated,
            :not_reviewed=>not_reviewed,
            :not_validated=>not_validated
        }
    }

    view :search,data 
end

