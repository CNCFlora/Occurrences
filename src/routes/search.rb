
get '/:db/search' do
    require_logged_in

    query = (params[:q] || "Aphelandra longiflora").gsub("&quot","\"")

    species = search(params[:db],"taxon",query)

    profiles = species.select {|doc| doc['taxonomicStatus']=='accepted'}
                      .map {|doc| doc['scientificNameWithoutAuthorship']}
                      .uniq 
                      .map {|name| {"scientificNameWithoutAuthorship"=>name}}

    occurrences = search(params[:db],"occurrence",query).sort_by {|x| x["occurrenceID"] || x["id"] || "z" }

    valid=0
    invalid=0
    reviewed=0
    validated=0
    not_reviewed=0
    not_validated=0
    eoo="n/a"
    aoo="n/a"
    eoo_poli="null"
    aoo_poli="null"
    i=0

    to_calc=[]

    occurrences.each{ |occ| 
        occ["occurrenceID"] = occ["id"] 
        occ["occurrenceID2"] = i

        occ["taxon"] = {}

        if !occ.has_key?("acceptedNameUsage") || occ["acceptedNameUsage"].nil?
          if occ.has_key?("scientificName") 
            if occ["scientificName"].index("f.")
              idx = occ["scientificName"].index("f.") -2
              occ["acceptedNameUsage"] = occ["scientificName"][0..idx]
            end
            if occ["scientificName"].index("subsp.")
              idx = occ["scientificName"].index("subsp.") -2
              occ["acceptedNameUsage"] = occ["scientificName"][0..idx]
            end
            if occ["scientificName"].index("var.")
              idx = occ["scientificName"].index("var.") -2
              occ["acceptedNameUsage"] = occ["scientificName"][0..idx]
            end
          end
        end

        species.each {|s|
            if s["scientificNameWithoutAuthorship"] == occ["scientificName"] or s["scientificName"] == occ["scientificName"] or s["scientificName"] == occ["acceptedNameUsage"] or s["scientificNameWithoutAuthorship"] == occ["acceptedNameUsage"]
                  if s["taxonomicStatus"] == 'synonym'
                    species.each { |ss| 
                      if s["acceptedNameUsage"] == ss["scientificName"] || s["acceptedNameUsage"] == "#{ss["scientificNameWithoutAuthorship"]} #{ss["scientificNameAuthorship"]}"
                        s = ss
                      end
                    }
                  end
                occ["taxon"] = s
                occ["acceptedNameUsage"] = s["acceptedNameUsage"]
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
            if occ["georeferenceVerificationStatus"] == "1" || occ["georeferenceVerificationStatus"] == "ok" then
                occ["sig-ok"]=true;
            else
                occ["sig-ok"]=false;
            end
        else
            not_reviewed += 1 
        end

        if occ.has_key?("verbatimValidation") && ( !occ.has_key?("validation") || occ["validation"] == {})
            occ["validation"] = occ["verbatimValidation"];
        end

        if occ.has_key?("validation")

            if !occ['validation'].is_a?(Hash) then 
              occ['validation']={}
            end

            if occ["validation"].has_key?("taxonomy")
               if (occ["validation"]["taxonomy"].nil? || occ["validation"]["taxonomy"] == 'valid') && 
                  (occ["validation"]["georeference"].nil? || occ['validation']['georeference'] == 'valid') &&
                  (occ['validation']['native'] != 'non-native') &&
                  (occ['validation']['presence'] != 'absent') &&
                  (occ['validation']['cultivated'] != 'yes') &&
                  (occ['validation']['duplicated'] != 'yes') 
                    occ["validation"]["status"]='valid';
                else
                    occ["validation"]["status"]='invalid';
                end
            else
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
                    to_calc.push occ
                    occ["valid"] = false
                    occ["invalid"] = false
                    not_validated += 1
                end
            else
                occ["valid"] = false
                occ["invalid"] = false
                not_validated += 1
                to_calc.push occ
            end

            occ["validation"].keys.each {|k|
                val = occ["validation"][k]
                if val.class == String and k != "remarks" and k != 'by' then
                    occ["#{k}-#{val}"]=true;
                end
            }
        else
            to_calc.push occ
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
        session[:user]["roles"].each {|c|
          if c["context"].downcase == params[:db].downcase then
            c["roles"].each {|r|
              if r.has_key? "entities" then
                  r["entities"].each {|e|
                      ents.push(e.upcase)
                  }
              end
            }
          end
        }
        occurrences.each {|o|
            o["can_validate"]=false
            if ents.include?("all") 
              o["can_validate"]=true
            end

            if !o['family'].nil? && ents.include?(o['family'].upcase)
                o["can_validate"] = true
            end

            if !o['scientificName'].nil? && ents.include?(o['scientificName'].upcase)
                o["can_validate"] = true
            end

            if o.has_key?("taxon")
                if !o["taxon"]['scientificNameWithoutAuthorship'].nil? && ents.include?(o["taxon"]['scientificNameWithoutAuthorship'].upcase)
                    o["can_validate"] = true
                end

                if o["taxon"].has_key?('family') && !o["taxon"]["family"].nil? && ents.include?(o["taxon"]['family'].upcase)
                    o["can_validate"] = true
                end

                if o["taxon"].has_key?("acceptedNameUsage") && !o["taxon"]['acceptedNameUsage'].nil?
                  o["taxon"]['acceptedNameUsage'] = o["taxon"]['acceptedNameUsage'].gsub(o["taxon"]["scientificNameAuthorship"],"")

                  if !o["taxon"]['acceptedNameUsage'].nil? && ents.include?(o["taxon"]['acceptedNameUsage'].upcase)
                      o["can_validate"] = true
                  end
                end
            end
            if o["can_validate"] == false
            end
        }
    end

    eoo_meters="n/a"
    aoo_meters="n/a"
    eoo_poli="null"
    aoo_poli="null"
    eoo="n/a"
    aoo="n/a"

    if to_calc.length >= 1 
        to_send=[]
        to_calc.each {|o|
            if o.has_key?("decimalLatitude") and o.has_key?("decimalLongitude") and o["decimalLatitude"] != nil and o["decimalLongitude"] != nil and o["sig-ok"] == true 
                po = {:decimalLatitude=>o["decimalLatitude"].to_f,:decimalLongitude=>o["decimalLongitude"].to_f}
                if po[:decimalLatitude] != 0.0 and po[:decimalLongitude] != 0.0
                    to_send.push(po)
                end
            end
        }
        if to_send.length >= 1
            begin
                eoo_j = RestClient::Request.execute(:method=>:post,:url=> "#{settings.dwc_services}/api/v1/analysis/eoo",
                               :payload=>JSON.dump(to_send), :headers=>{ :content_type => "json", :accept => :json }, :timeout => 15)
                eoo_r = JSON.parse(eoo_j)
                eoo_meters = eoo_r["area"]*1000
                eoo_kmeters = (eoo_meters.to_f/1000).round(2)
                eoo_poli = {"type"=>"Feature","geometry"=> eoo_r["geo"] }.to_json
                eoo = "#{eoo_kmeters.to_s.reverse.gsub(".",",").gsub(/(\d{3})(?=\d)/, '\\1.').reverse}km²"
            rescue Exception => e
                puts "EOO exception #{e.message}"
            end

            begin
                aoo_j = RestClient::Request.execute(:method=>:post,:url=> "#{settings.dwc_services}/api/v1/analysis/aoo",
                               :payload=>JSON.dump(to_send), :headers=>{ :content_type => "json", :accept => :json }, :timeout => 15)
                aoo_r = JSON.parse(aoo_j)
                aoo_meters = aoo_r["area"]*1000
                aoo_kmeters = (aoo_meters.to_f/1000).round(2)
                aoo_poli = {"type"=>"Feature","geometry"=> aoo_r["geo"] }.to_json
                aoo = "#{aoo_kmeters.to_s.reverse.gsub(".",",").gsub(/(\d{3})(?=\d)/, '\\1.').reverse}km²"
            rescue Exception => e
                puts "AOO exception #{e.message}"
            end
        end
    end

    data = {
        :db=>params[:db],
        :result=>occurrences,
        :query=>query,
        :eoo_poli=>eoo_poli,
        :aoo_poli=>aoo_poli,
        :to_profiles=>profiles,
        :stats=>{
            :eoo=>eoo,
            :aoo=>aoo,
            :eoo_meters=>eoo_meters,
            :aoo_meters=>aoo_meters,
            :total=>total,
            :valid=>valid,
            :invalid=>invalid,
            :reviewed=>reviewed,
            :validated=>validated,
            :not_reviewed=>not_reviewed,
            :not_validated=>not_validated
        }
    }

    if params[:json]
      content_type 'application/json'
      data.to_json
    elsif params[:csv]
      content_type 'application/csv'
      attachment 'ocorrencias.csv'
      data[:result].each {|occ|
        occ[:json] = nil
      }
      RestClient.post "#{settings.dwc_services}/api/v1/convert?from=json&to=csv",
                        data[:result].to_json, :content_type => :json
    else
      view :search,data 
    end
end

