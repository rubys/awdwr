module TestHelper
  def show(xml, str)
    res = eval(str)
    xml.dt(:newline => "yes") do
      xml.inlinecode("<%= " + str + " %>")
    end
    xml.dd do
      xml.p(res)
    end
  end
  
end
