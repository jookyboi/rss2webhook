class HomeController < ApplicationController
  def index
    @markdown = Redcarpet::Markdown.new(
           Redcarpet::Render::HTML,
           :no_intra_emphasis => true,
           :fenced_code_blocks => true
   )

    @readme = File.open(File.join(Rails.root, 'README.md')).read
  end
end