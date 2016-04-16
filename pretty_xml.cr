# XML pretty printer
# ~~~~~~~~~~~~~~~~~~~
#
# Reads XML from STDIN and outputs it formatted and colored to STDOUT.
# Incomplete implementation, adapted from crystal json sample. Just for trying out crystal.
#
# Usage: echo '<?xml version="1.0"?><name><first>Cahit</first><last>Arf</last></name>' | ./pretty_xml
# Usage: echo "$(<test.xml)" | ./pretty_xml

require "xml"
require "colorize"

class PrettyXMLPrinter
  @current_indent = 0
  @@colors = {
    :symbol   => :blue,
    :attr     => :yellow,
    :tag_name => :red,
    :text     => :white,
  }

  def initialize(@indent : Int = 2, @compact : Bool = true, @colorize : Bool = true, @colors : Hash(Symbol, Symbol) = @@colors)
    @input = ""
    @output = MemoryIO.new
  end

  def print(@input : (String | IO), @output)
    print
  end

  def print(@input : (String | IO))
    print
    @output.to_s
  end

  private def print
    @doc = XML.parse(@input)
    @current_indent = 0
    print_node(@doc.not_nil!)
  end

  private def print_node(node : XML::Node)
    case node.type
    when XML::Type::ELEMENT_NODE
      print_element(node)
    when XML::Type::TEXT_NODE
      unless node.content =~ /^\s*$/
        unless @compact
          p "\n"
          print_indent
        end
        print_text(node.to_s)
        @skip_indent = true if @compact
      end
    when XML::Type::DOCUMENT_NODE
      print_symbol("<?")
      print_tag_name("xml")
      print_attr(" version", node.version) if node.version
      print_attr(" encoding", node.encoding) if node.encoding
      print_symbol("?>")
      node.children.each { |c| print_node(c) }
    else
      p node.type
      p node.name
      p node.content
      p node
    end
  end

  private def open_tag(node, self_closing = false)
    p "\n"
    print_indent

    print_symbol "<"
    print_name(node)
    node.attributes.each do |attr|
      p ' '
      print_attr(attr.name, attr.content)
    end

    namespace_definitions(node).each do |ns|
      prefix = ns.prefix
      next unless prefix

      p ' '
      print_attr("xmlns:" + prefix, ns.href)
    end

    print_symbol " /" if self_closing
    print_symbol ">"
  end

  private def print_element(node)
    children = node.children
    if children.size == 0
      open_tag(node, true)
    else
      open_tag(node)
      @current_indent += 1
      children.each do |child|
        print_node(child)
      end
      @current_indent -= 1
      close_tag(node)
    end
  end

  private def close_tag(node)
    if @skip_indent
      @skip_indent = false
    else
      p "\n"
      print_indent
    end

    print_symbol("</")
    print_name(node)
    print_symbol(">")
  end

  private def print_name(node)
    ns = node.namespace
    if ns
      print_tag_name(ns.prefix)
      print_symbol(":")
    end
    print_tag_name(node.name)
  end

  private def print_attr(key, value)
    print_attr(key)
    print_symbol(%(="))
    print_attr(value)
    print_symbol(%(\"))
  end

  {% for kind in %w(attr symbol tag_name text) %}
    private def print_{{kind.id}}(value : String?)
      p value, :{{kind}}
    end
  {% end %}

  private def print_indent
    @current_indent.times { @output << (" " * @indent) }
  end

  private def p(value)
    @output << value
  end

  private def p(value, color)
    if @colorize
      value = value.colorize(@colors[color])
    end
    p value
  end

  private def namespace_definitions(node : XML::Node)
    namespaces = [] of XML::Namespace

    node_ptr = node.to_unsafe
    ns_ptr = node_ptr.value.ns_def
    while ns_ptr
      namespaces << XML::Namespace.new(node.document, ns_ptr)
      ns_ptr = ns_ptr.value.next
    end

    namespaces
  end
end

printer = PrettyXMLPrinter.new
printer.print(STDIN, STDOUT)
STDOUT.puts
