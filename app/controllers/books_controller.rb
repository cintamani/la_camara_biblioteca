class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]
  before_action :load_genres, only: %i[new create edit update]

  def index
    @books = Book.includes(:genres)

    if params[:search].present?
      @books = @books.search(params[:search])
    end

    if params[:genre].present?
      @books = @books.by_genre(params[:genre])
    end

    @books = @books.order(created_at: :desc)
    @parent_genres = Genre.roots.sorted.includes(:children)
  end

  def show
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book, notice: "El libro se ha añadido correctamente al archivo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "El libro se ha actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_url, notice: "El libro se ha eliminado correctamente del archivo."
  end

  def lookup_isbn
    @book = Book.new
    load_genres

    if params[:isbn].blank?
      flash.now[:alert] = "Por favor, introduce un ISBN."
      return render :new, status: :unprocessable_entity
    end

    begin
      book_data = GoogleBooksService.fetch_by_isbn(params[:isbn])

      @book.title = book_data[:title]
      @book.author = book_data[:author]
      @book.isbn = book_data[:isbn]
      @book.genre_list = book_data[:genres].join(", ") if book_data[:genres].present?

      flash.now[:notice] = "¡Libro encontrado! Revisa los detalles y guarda."
    rescue GoogleBooksService::BookNotFoundError
      flash.now[:alert] = "No se encontró ningún libro con ese ISBN."
    rescue GoogleBooksService::ApiError => e
      flash.now[:alert] = "Error al contactar la API de Google Books: #{e.message}"
    rescue StandardError => e
      flash.now[:alert] = "Ocurrió un error inesperado: #{e.message}"
    end

    render :new
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def load_genres
    @parent_genres = Genre.roots.sorted.includes(:children)
  end

  def book_params
    params.require(:book).permit(:title, :author, :isbn, :genre_list, genre_ids: [])
  end
end
