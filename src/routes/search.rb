
get '/search' do
    query = (params[:q] || "Aphelandra longiflora").gsub("&quot","\"")

    species = search("taxon",query)

    occurrences = search("occurrence",query)

    valid=0
    invalid=0
    reviewed=0
    validated=0
    not_reviewed=0
    not_validated=0
    eoo="n/a"
    aoo="n/a"
    eoo_poli=nil
    aoo_poli=nil
    i=0

    to_calc=[]

    occurrences.each{ |occ| 
        occ[:occurrenceID2] = i

        occ[:taxon] = {}
        species.each {|s|
            if s[:scientificNameWithoutAuthorship] == occ[:scientificName] or s[:scientificName] == occ[:scientificName]
                occ[:taxon] = s
            end
        }

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
            not_reviewed += 1 
        end

        if occ.has_key?("validation")

            if occ["validation"].has_key?( "taxonomy" ) && occ["validation"].has_key?( "georeference" )
               if occ["validation"]["taxonomy"] == 'valid' && occ['validation']['georeference'] == 'valid'
                    occ["validation"]["status"]='valid';
                else
                    occ["validation"]["status"]='invalid';
                end
            end

            if occ["validation"].has_key?("status")
                if occ["validation"]["status"] === 'valid'
                    validated += 1
                    valid += 1
                    occ["valid"] = true
                    occ["invalid"] = false 
                    to_calc.push occ
                elsif occ["validation"]["status"] === 'invalid'
                    validated += 1
                    invalid += 1
                    occ["valid"] = false
                    occ["invalid"] = true
                else 
                    occ["valid"] = false
                    occ["invalid"] = false
                    not_validated += 1
                end
            end

            occ["validation"].keys.each {|k|
                val = occ["validation"][k]
                if val.class == String then
                    occ["#{k}-#{val}"]=true;
                end
            }
        else
            occ["valid"] = false
            occ["invalid"] = false
            not_validated += 1
        end

        occ[:json] = JSON.dump(occ) 
        i += 1
    }
    total = i

    if session[:logged]
        ents=[]
        session[:user]["roles"].each {|r|
            if r.has_key? "entities" then
                r["entities"].each {|e|
                    ents.push(e.upcase)
                }
            end
        }
        occurrences.each {|o|
            s=o[:taxon]
            o["can_validate"] = (ents.include?(s["scientificNameWithoutAuthorship"].upcase) or ents.include?(s["family"].upcase))
        }
    end

    if to_calc.length >= 1 
        to_send=[]
        to_calc.each {|o|
            if o.has_key?("decimalLatitude") and o.has_key?("decimalLongitude") and o["decimalLatitude"] != nil and o["decimalLongitude"] != nil
                to_send.push(:decimalLatitude=>o["decimalLatitude"].to_f,:decimalLongitude=>o["decimalLongitude"].to_f)
            end
        }
        eoo_r = RestClient.post "#{settings.dwc_services}/api/v1/analysis/eoo",
                       JSON.dump(to_send), :content_type => "json", :accept => :json
        aoo_r = RestClient.post "#{settings.dwc_services}/api/v1/analysis/aoo",
                       JSON.dump(to_send), :content_type => "json", :accept => :json
        eoo_meters = eoo_r.area
        aoo_meters = aoo_r.area
        eoo_kmeters = (eoo_meters.to_f/1000).round(2)
        aoo_kmeters = (aoo_meters.to_f/1000).round(2)
        eoo_poli = eoo_r.polygon
        aoo_poli = aoo_r.polygon
        eoo = "#{eoo_kmeters}km²"
        aoo = "#{aoo_kmeters}km²"
    end

    data = {
        :result=>occurrences,
        :query=>query,
        :stats=>{
            :eoo=>eoo,
            :eoo_poli=>eoo_poli,
            :aoo=>aoo,
            :aoo_poli=>aoo_poli,
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

