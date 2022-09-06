class Admin::MoviesController < ApplicationController
    #moviesデータベースと接続してデータを取り出す。
    def index
        @movies = Movie.all
    end
    
    # station 3 でnewアクションを追加する。
    # GET /admin/movies/new
    def new
      @movie = Movie.new
    end
    # POST /admin/movies or /admin/movies.json
    def create
      @movie = Movie.new(movie_params)

      respond_to do |format|
        if @movie.save
          format.html { redirect_to @movie, notice: "Movie was successfully created." }
          format.json { render :show, status: :created, location: @movie }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @movie.errors, status: :unprocessable_entity }
        end
      end
    end

    #元のmoviesコントローラからコピーしてきた。
    private
    # Use callbacks to share common setup or constraints between actions.
    def set_movie
      @movie = Movie.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def movie_params
      params.fetch(:movie, {})
    end
end
