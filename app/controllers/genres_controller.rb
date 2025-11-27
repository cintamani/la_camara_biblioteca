class GenresController < ApplicationController
  before_action :set_genre, only: %i[edit update destroy]

  def index
    @parent_genres = Genre.roots.sorted.includes(:children)
  end

  def new
    @genre = Genre.new(parent_id: params[:parent_id])
    @parent_genres = Genre.roots.sorted
  end

  def create
    @genre = Genre.new(genre_params)

    if @genre.save
      redirect_to genres_path, notice: "El género se ha creado correctamente."
    else
      @parent_genres = Genre.roots.sorted
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parent_genres = Genre.roots.where.not(id: @genre.id).sorted
  end

  def update
    if @genre.update(genre_params)
      redirect_to genres_path, notice: "El género se ha actualizado correctamente."
    else
      @parent_genres = Genre.roots.where.not(id: @genre.id).sorted
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @genre.books.any?
      redirect_to genres_path, alert: "No se puede eliminar un género que tiene libros asociados."
    else
      @genre.destroy
      redirect_to genres_path, notice: "El género se ha eliminado correctamente."
    end
  end

  private

  def set_genre
    @genre = Genre.find(params[:id])
  end

  def genre_params
    params.require(:genre).permit(:name, :parent_id)
  end
end
