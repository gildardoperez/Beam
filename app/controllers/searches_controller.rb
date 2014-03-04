require 'instagram'

class SearchesController < ApplicationController
	#  handle revoked access from Instagram
	rescue_from Instagram::BadRequest, with: :default_user

  def index
  	# check is the search field is empty
  	if params[:search] == ""
  		flash[:notice] = "You did not search for a hashtag so we search puppies for you!"
  		params[:search] = "puppies"
  	end

    # binding.pry

  	# when user logs out of instagram we need to check when our app gets refreshed or live update it?
  	if session[:access_token]
  		if params[:search]
        if current_user.albums.find_by(title: params[:search]) == nil
          @default_album = current_user.albums.new(title: params[:search])
          if !@default_album.save
            flash[:error] = "There was a problem creating the album #{params[:search]}"
          end
        else
          @default_album = current_user.albums.find_by(title: params[:search])
        end

        # search username 
        if params[:search].index("@")
          user_id = session[:client].user_search(params[:search][1..-1])[0].id
          @instagram_results = session[:client].user_recent_media(user_id, {count: 10})
        # search hashtag
        else
          @instagram_results = session[:client].tag_recent_media(params[:search], {count: 10})
          # @total_results = session[:client].tag(params[:search])
        end
  			
        
  			@next_url = @instagram_results.pagination.next_url
  		end
  	else
  		# for visitors
  		if params[:search]
        # search username 
        if params[:search].index("@")
          user_id = session[:client].user_search(params[:search][1..-1])[0].id
          @instagram_results = Instagram.user_recent_media(user_id, {count: 10})
        # search hashtag
        else
          @instagram_results = Instagram.tag_recent_media(params[:search], {count: 10})
          # @total_results = session[:client].tag(params[:search])
        end
  			
        # @total_results = Instagram.tag(params[:search])
  			@next_url = @instagram_results.pagination.next_url
  		end
  	end
  end

  def create
  end

protected
  #  handle revoked access from Instagram
  def default_user
  	# reset access_token
  	session[:access_token] = nil
  	# notify users
  	flash[:error] = 'access token revoked through instagram'
  	redirect_to searches_path
  end
end
