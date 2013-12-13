require "spec_helper"
require "builder"

describe "cleaning vcards" do

  specify "cleaning" do
    open("cleaning.html", "w") do |html|
      b = Builder::XmlMarkup.new(:target => html)
      b.html do
        b.head do |head|
          head.title "vcard-cleaning"
          head.link(:type => "text/css", :rel => "stylesheet", :media => "screen", :href => "http://tijnschuurmans.nl/style/minimal.css")
        end
        b.body do
          b.table do |t|
            t.tr do
              t.th "original"
              t.th "clean"
            end
            Dir.glob("#{VCARDS_ROOT}/faulty/*.vcf").sort.each do |f|
              #puts f
              x = Vcard.from_vcard(File.read(f))
              t.tr do
                t.td { t.pre x}
                t.td { t.pre(x.super_clean!); t.pre(x.signature)}
              end
            end
          end
        end
      end
    end
  end
end
