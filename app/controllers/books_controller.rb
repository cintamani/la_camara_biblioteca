class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]
  before_action :load_genres, only: %i[new create edit update]
  before_action :require_login, except: %i[index show]

  def index
    @books = Book.includes(:genres)

    if params[:search].present?
      @books = @books.search(params[:search])
    end

    if params[:genre].present?
      @books = @books.by_genre(params[:genre])
    end

    @books = @books.order(created_at: :desc)
    @pagy, @books = pagy(@books)
    @parent_genres = Genre.roots.sorted.includes(:children)
  end

  def show
  end

  def new
    @book = Book.new
  end

  def create
    # Get ISBNs from either isbns_list or isbn param
    new_isbns = extract_isbns_from_params

    # Check if a book with any of these ISBNs already exists
    if new_isbns.any?
      new_isbns.each do |isbn|
        existing_by_isbn = Book.find_by_isbn(isbn)
        if existing_by_isbn
          redirect_to existing_by_isbn, notice: "Este ISBN ya está registrado en el libro '#{existing_by_isbn.title}'."
          return
        end
      end
    end

    # Check for duplicate by title and author
    existing = Book.find_duplicate(book_params[:title], book_params[:author])

    if existing && new_isbns.any?
      # Add the ISBNs to the existing book
      new_isbns.each { |isbn| existing.add_isbn(isbn) }
      # Merge genres if any
      if book_params[:genre_ids].present?
        new_genre_ids = book_params[:genre_ids].map(&:to_i) - existing.genre_ids
        existing.genre_ids += new_genre_ids
      end
      existing.save!
      added_isbns = new_isbns.join(", ")
      redirect_to existing, notice: "Este libro ya existía. Se ha añadido el ISBN (#{added_isbns}) al registro existente."
      return
    end

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

    # Preserve the ISBN in the form even if lookup fails
    @book.isbn = params[:isbn]

    # Check if ISBN already exists
    existing = Book.find_by_isbn(params[:isbn])
    if existing
      redirect_to existing, notice: "Este ISBN ya está registrado en el libro '#{existing.title}'."
      return
    end

    begin
      book_data = GoogleBooksService.fetch_by_isbn(params[:isbn])

      # Check for potential duplicate by title/author
      potential_duplicate = Book.find_duplicate(book_data[:title], book_data[:author])
      if potential_duplicate
        flash.now[:notice] = "¡Atención! Ya existe un libro con el mismo título y autor: '#{potential_duplicate.title}'. Si guardas, el ISBN se añadirá al libro existente."
      else
        flash.now[:notice] = "¡Libro encontrado! Revisa los detalles y guarda."
      end

      @book.title = book_data[:title]
      @book.author = book_data[:author]
      @book.isbn = book_data[:isbn]
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
    params.require(:book).permit(:title, :author, :isbn, :isbns_list, :copies, :genre_list, :status, :borrower_name, genre_ids: [])
  end

  def extract_isbns_from_params
    isbns = []

    # From isbns_list (comma-separated)
    if book_params[:isbns_list].present?
      isbns += book_params[:isbns_list].split(",").map { |i| Book.normalize_isbn(i) }.reject(&:blank?)
    end

    # From single isbn param (for backwards compatibility)
    if book_params[:isbn].present?
      isbns << Book.normalize_isbn(book_params[:isbn])
    end

    isbns.uniq
  end
end
