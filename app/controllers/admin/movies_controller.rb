class Admin::MoviesController < ApplicationController
    #moviesデータベースと接続してデータを取り出す。
    def index
        @movies = Movie.all
    end
end
