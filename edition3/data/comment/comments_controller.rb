class CommentsController < ApplicationController

  before_filter :find_article
 
  def new
    @comment = Comment.new
  end

  def edit
    @comment = @article.comments.find(params[:id])
  end

  def create
    @comment = Comment.new(params[:comment])
    if (@article.comments << @comment)
      redirect_to article_url(@article)
    else
      render :action => :new
    end
  end

  def update
    @comment = @article.comments.find(params[:id])
    if @comment.update_attributes(params[:comment])
      redirect_to article_url(@article)
    else
      render :action => :edit
    end
  end

  def destroy
    comment = @article.comments.find(params[:id])
    @article.comments.delete(comment)
    redirect_to article_url(@article)
  end
 
private

  def find_article
    @article_id = params[:article_id]
    return(redirect_to(articles_url)) unless @article_id
    @article = Article.find(@article_id)
  end

end
