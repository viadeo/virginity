module Virginity


  class BaseField < ContentLine
    def params_to_xml!(params, builder)
      builder.params(:type => "array") do
        params.each do |p|
          builder.tag!(p.key, p.value, :type => "string")
        end
      end
    end

    def extra_fields_to_xml(fields, builder)
      fields.each_pair { |k,v| builder.tag!(k, v) } unless fields.nil?
    end
  end


  class BaseField < ContentLine
    def params_to_xml
      s = ""
      unless params.empty?
        s << "<params>"
        params.each do |p|
          s << xml_element(p.key, p.value)
        end
        s << "</params>"
      end
      s
    end

#     def params_to_xml
#       return "" if params.empty?
#       "<params>#{params.map {|p| xml_element(p.key, p.value) }.join}</params>"
#     end

    def value_to_xml
      xml_element(@value, @value.strip)
    end

    def to_xml
      s = "<#{name.downcase}>"
      s << xml_element("group", group) unless group.nil?
      s << params_to_xml
      s << value_to_xml
      s << "</#{name.downcase}>"
    end
  end


  class Email < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.email(:index => api_id ) do
        xml.id api_id, :type => "string"
#           params_to_xml!(params, xml)
        xml.address address
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


  class Tel < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.telephone(:index => api_id ) do
        xml.id api_id, :type => "string"
#           params_to_xml!(params, xml)
        xml.number number
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


  class Url < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.url(:index => api_id) do
        xml.id api_id, :type => "string"
        xml.text text
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


  class Adr < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.address(:index => api_id) do
        xml.id api_id, :type => "string"
#           params_to_xml!(params, xml)
        components.each do |component|
          xml.tag!(component, send(component))
        end
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


  class Org < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.organisation :index => api_id do
        xml.id api_id, :type => "string"
        xml.name orgname
        xml.unit1 unit1
        xml.unit2 unit2
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


  class Impp < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.impp(:index => api_id ) do
        xml.id api_id, :type => "string"
        xml.scheme scheme
        xml.address address
        xml.value text
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


  class TextField < BaseField
    def to_xml(options = {})
      xml = options[:builder] || Builder::XmlMarkup.new(options)
      xml.note(:index => api_id) do
        xml.id api_id, :type => "string"
        xml.text text
        extra_fields_to_xml(options[:include], xml)
      end
      xml.target!
    end
  end


end
