class TestController < ApplicationController
  def rdoc
    @value = 123
  end

  def date_dump
  end

#START:calculate
  def calculate
    if request.post?
      @errors = []
      arg1 = convert_float(:arg1)
      arg2 = convert_float(:arg2)
      op   = convert_operator(:operator)
      
      if @errors.empty?
        begin
          @result = op.call(arg1, arg2)
        rescue Exception => err
          @result = err.message
        end
      end
    end
  end

  private

  def convert_float(name)
    if params[name].blank?
      @errors << "#{name} missing"
    else
      begin
        Float(params[name])
      rescue Exception => err
        @errors << "#{name}: #{err.message}"
        nil
      end
    end
  end

  def convert_operator(name)
    case params[name]
    when "+" then proc {|a,b| a+b}
    when "-" then proc {|a,b| a-b}
    when "*" then proc {|a,b| a*b}
    when "/" then proc {|a,b| a/b}
    else
      @errors << "Missing or invalid operator"
      nil
    end
  end
#END:calculate
end
    
