#Kanon User Model
module Kanon
  module Models
    DB = Sequel.sqlite

    DB.create_table :users do
      primary_key :id
      String :firstName
      String :lastName
      String :gender
      String :nric
      String :address1
      String :zipcode
      String :phone
      String :username
      String :password_hash
      String :researcher_id
      String :research_category
      Boolean :isAdmin
      String :qualification
      String :qualification_name
    end

    class User < Sequel::Model
      plugin :secure_password, cost: 12, include_validations: false, digest_column: :password_hash

      def validate
        super
      end

      def getResearchCategory(researcher)
        researchCat = ""
        parsedResearcher = JSON.parse(researcher.body, :symbolize_name => true)
        parsedResearcher["research_category"].each do |category|
          researchCat << category.to_s + ","
        end
        return researchCat.chomp(',')
      end

      def getResearcherObject(user, username) 
        researcher = Kanon::WebAPI.restGetResearcher(username)
        parsedResearcher = JSON.parse(researcher.body, :symbolize_name => true)
        user.firstName = parsedResearcher["firstname"]
        user.lastName = parsedResearcher["lastname"]
        user.gender = parsedResearcher["gender"]
        user.nric = parsedResearcher["nric"]
        user.address1 = parsedResearcher["address1"]
        user.zipcode = parsedResearcher["zipcode1"]
        user.phone = parsedResearcher["phone1"]
        user.researcher_id = parsedResearcher["researcher_id"]
        user.research_category = getResearchCategory(researcher)
        user.isAdmin = if parsedResearcher["isAdmin"] == 'true' then true else false end
        user.qualification = parsedResearcher["qualification"]
        user.qualification_name = parsedResearcher["qualification_name"]
      end
    end
  end
end
