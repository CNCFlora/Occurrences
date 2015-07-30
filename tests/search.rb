
require_relative 'base.rb'

describe "Simple search?" do

    before (:each) do 
      before_each() 
      login_before_each()
    end

    after (:each) do after_each() end

    it "Gets specie by name" do
        upload()

        taxon= "Aphelandra%20longiflora"
        get "/cncflora_test/specie/#{taxon}"
        follow_redirect!
        expect(last_response.body).to have_tag("td#total",:text=>"3")

        id1 = 'UNICAMP:UEC:10137'
        id2 = 'MBM:MBM:19751'
        id3 = 'MBM:MBM:137990'

        expect(last_response.body).to have_tag("a",:text=>"urn:occurrence:#{id1}")
        expect(last_response.body).to have_tag("a",:text=>"urn:occurrence:#{id2}")
        expect(last_response.body).to have_tag("a",:text=>"urn:occurrence:#{id3}")
    end

end
