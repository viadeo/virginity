module Virginity

  class Email < BaseField
    def as_json(options = {})
      { :email => {
          :id => api_id,
          :params => params,
          :address => address
      }}
    end
  end


  class Tel < BaseField
    def as_json(options = {})
      { :tel => {
          :id => api_id,
          :params => params,
          :number => number
      }}
    end
  end


  class Url < BaseField
    def as_json(options = {})
      { :url => {
          :id => api_id,
          :text => text
      }}
    end
  end


  class Adr < BaseField
    def as_json(options = {})
      hash = { :adr => {
          :id => api_id,
          :params => params,
      }}
      components.each do |component|
        hash[component] = send(component))
      end
      hash
    end
  end


  class Org < BaseField
    def as_json(options = {})
      { :org => {
          :id => api_id,
          :name => orgname,
          :unit1 => unit1,
          :unit2 => unit2
      }}
    end
  end


  class Impp < BaseField
    def as_json(options = {})
      { :impp => {
          :id => api_id,
          :scheme => scheme,
          :address => address,
          :text => text
      }}
    end
  end


  class Note < BaseField
    def as_json(options = {})
      { :note => {
          :id => api_id,
          :text => text
      }}
    end
  end

end
