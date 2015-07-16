
require_relative 'base.rb'

describe "Test login and checklist switch" do

    #before (:each) do before_each() end

    #after (:each) do after_each() end

    it "Gets login page." do
        get "/"
        expect(last_response.body).to have_tag("body") do
            with_tag "#login" 
            without_tag "#logout"  
        end
        expect(last_response.body).to have_tag("h2", "Necessário fazer login" )  
    end

    it "Goes to home page after login." do
        post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }
        get "/"
        expect(last_response.body).to have_tag("#logout")
        expect(last_response.body).not_to have_tag("#login")
    end

    it "Change checklist active" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/"
      #expect(last_response.body).to have_tag('a',:text=>'CNCFLORA')
      expect(last_response.body).to have_tag('a',:text=>'CNCFLORA TEST')

      get "/cncflora_test/workflow"

      expect(last_response.body).to have_tag('a',:text=>'Recortes')
      expect(last_response.body).to have_tag('a',:text=>'Resumo')
      expect(last_response.body).to have_tag('a',:text=>'Famílias')

      expect(last_response.body).to have_tag('span',:class=>'db',:text=>'Recorte: CNCFLORA TEST')
    end


end

