require 'erb'
require 'erubis'

# BASED ON CODE FROM RAILS

class String
  alias :append= :<<
end

class Neorubis < Erubis::Eruby
  include Erubis::ErboutEnhancer

  def add_preamble(src)
    @newline_pending = 0
    src << "@output_buffer = '';"
  end

  def add_text(src, text)
    return if text.empty?

    if text == "\n"
      @newline_pending += 1
    else
      src << "@output_buffer.append='"
      src << "\n" * @newline_pending if @newline_pending > 0
      src << escape_text(text)
      src << "'.freeze;"

      @newline_pending = 0
    end
  end

  # Erubis toggles <%= and <%== behavior when escaping is enabled.
  # We override to always treat <%== as escaped.
  def add_expr(src, code, indicator)
    case indicator
    when "=="
      add_expr_escaped(src, code)
    else
      super
    end
  end

  def add_expr_literal(src, code)
    flush_newline_if_pending(src)
    if /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/ =~ code
      src << "@output_buffer.append= " << code
    else
      src << "@output_buffer.append=(" << code << ");"
    end
  end

  alias :add_expr_escaped :add_expr_literal

  def add_stmt(src, code)
    flush_newline_if_pending(src)
    super
  end

  def add_postamble(src)
    flush_newline_if_pending(src)
    src << "@output_buffer.to_s"
  end

  def flush_newline_if_pending(src)
    if @newline_pending > 0
      src << "@output_buffer.append='#{"\n" * @newline_pending}'.freeze;"
      @newline_pending = 0
    end
  end
end

Nanoc::Filter.define(:better_erb) do |content, _params|
  # Create context
  context = ::Nanoc::Int::Context.new(assigns)

  # Get binding
  proc = assigns[:content] ? -> { assigns[:content] } : nil
  assigns_binding = context.get_binding(&proc)

  # Get result
  Neorubis.new(content, filename: filename).result(assigns_binding)
end
