class PartialController < ApplicationController

  def test1
    @article = "fred"
    def @article.title
      "my title"
    end
    def @article.body
      "my body"
    end
  end

    
end
