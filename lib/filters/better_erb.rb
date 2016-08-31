require 'action_view'

class String
  alias :append= :<<
  alias :safe_append= :append=
end

class MyContext < ::Nanoc::Int::Context
  attr_accessor :output_buffer
end

Nanoc::Filter.define(:better_erb) do |content, _params|
  # Create context
  context = MyContext.new(assigns)
  context.output_buffer = ''

  # Get binding
  proc = assigns[:content] ? -> { assigns[:content] } : nil
  assigns_binding = context.get_binding(&proc)

  # Get result
  ActionView::Template::Handlers::Erubis
      .new(content, filename: filename)
      .result(assigns_binding)
end
