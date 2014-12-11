
get '/:db/workflow' do
    data = []

    if session[:logged]

        ents=[]

        session[:user]["roles"].each {|ctx|
            if ctx["context"] == params[:db] then
              ctx["roles"].each {|r|
                if r.has_key? "entities" then
                    r["entities"].each {|e|
                        ents.push(e.upcase)
                    }
                end
              }
            end
        }

        query = "NOTHING"
        #puts ents

        if ents.length >= 1 then
            query =  "taxonomicStatus:\"accepted\""
            query << " AND ( "
            ents.each{ |e| query << " \"#{e}\" " }
            query << " ) "
        end

        families = [];

        #puts query

        search(params[:db],"taxon",query)
            .each { |e| families.push e['family'].upcase }

        #puts families

        families.uniq.each {|f|
            taxon = {
                :family=>f,
                :reviewed=>0,
                :not_reviewed=>0,
                :validated=>0,
                :not_validated=>0,
                :valid=>0,
                :invalid=>0,
                :total=>0
            }

            occs=[]
            names=[]
            search(params[:db],"taxon","family:\"#{f}\" AND taxonomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecies\")")
                .each {|s|
                    if ents.include?(s["scientificNameWithoutAuthorship"].upcase)  or ents.include?(s["family"].upcase)
                        names.push(s['scientificNameWithoutAuthorship'])
                        search(params[:db],"taxon","taxonomicStatus:\"synonym\" AND acceptedNameUsage:\"#{s['scientificNameWithoutAuthorship']}*\"")
                        .each {|ss| names.push ss['scientificNameWithoutAuthorship']}
                    end
                }

            search(params[:db],"occurrence","\"#{ names.select {|n| n != nil }.join("\" OR \"") }\"")
                .each {|occ|
                    taxon[:total] += 1;

                    if occ.has_key?("georeferenceVerificationStatus") 
                        taxon[:reviewed] += 1;
                    else
                        taxon[:not_reviewed] += 1;
                    end

                    if occ.has_key?("validation")
                        if occ["validation"].has_key?("by")
                            taxon[:validated] += 1
                        else
                            taxon[:not_validated] += 1
                        end
                    else
                        taxon[:not_validated] += 1
                    end
                }
            
            data.push(taxon)

        }

    end

    view :workflow,{:data=>data,:db=>params[:db]}
end
