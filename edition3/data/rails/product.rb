class Product < ActiveRecord::Base

  def self.import(source)
    if source =~ /^http:/
      input = Net::HTTP.get(URI.parse(source))
    else
      input = File.open(source) {|file| file.read}
    end

    REXML::Document.new(input).each_element('//product') do |xproduct|
      base_id  = xproduct.elements['id'].text

      product = self.find_by_base_id(base_id) || self.new 

      product.base_id     = base_id
      product.title       = xproduct.elements['title'].text
      product.description = xproduct.elements['description'].text
      product.image_url   = xproduct.elements['image-url'].text
      product.price       = xproduct.elements['price'].text

      product.save!
    end
  end

end
