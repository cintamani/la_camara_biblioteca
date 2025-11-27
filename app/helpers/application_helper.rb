module ApplicationHelper
  def grouped_genre_options(parent_genres, selected = nil)
    options = [[ "Todos los Géneros", "" ]]

    parent_genres.each do |parent|
      options << [ parent.name, parent.name ]
      parent.children.sorted.each do |child|
        options << [ "  └ #{child.name}", child.name ]
      end
    end

    options_for_select(options, selected)
  end
end
