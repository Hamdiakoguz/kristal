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
  def initialize(@input, @output)
    @doc = XML.parse(@input)
    @indent = 0
  end

  @@colors = {
    :symbol => :blue,
    :attr   => :yellow,
    :tag    => :red,
    :text   => :white,
  }

  def colors=(val)
    @@colors = val
  end

  def colors
    @@colors
  end

  def print
    print_node(@doc)
  end

  def print_node(node)
    case node.type
    when XML::Type::ELEMENT_NODE
      print_element(node)
    when XML::Type::TEXT_NODE
      unless node.content =~ /^\s*$/
        print_text(node)
        @skip_indent = true
      end
    when XML::Type::DOCUMENT_NODE
      print_symbol "<?"
      p "xml", :tag
      print_attr(" version", node.version) if node.version
      print_attr(" encoding", node.encoding) if node.encoding
      print_symbol "?>"
      node.children.each { |c| print_node(c) }
    else
      print node.type
      print node.name
      print node.content
      print node
    end
  end

  def open_tag(node, self_closing = false)
    print "\n"
    print_indent

    print_symbol "<"
    print_name(node)
    node.attributes.each do |attr|
      print ' '
      print_attr(attr.name, attr.content)
    end

    namespace_definitions(node).each do |ns|
      prefix = ns.prefix
      next unless prefix

      print ' '
      print_attr("xmlns:" + prefix, ns.href)
    end

    print_symbol " /" if self_closing
    print_symbol ">"
  end

  def print_element(node)
    children = node.children
    if children.size == 0
      open_tag(node, true)
    else
      open_tag(node)
      @indent += 1
      children.each do |child|
        print_node(child)
      end
      @indent -= 1
      close_tag(node)
    end
  end

  def close_tag(node)
    if @skip_indent
      @skip_indent = false
    else
      print "\n"
      print_indent
    end

    print_symbol("</")
    print_name(node)
    print_symbol(">")
  end

  def print_name(node)
    ns = node.namespace
    if ns
      p ns.prefix, :tag
      print_symbol ":"
    end
    p node.name, :tag
  end

  def print_attr(key, value)
    p key, :attr
    p "=\"", :symbol
    p value, :attr
    p "\"", :symbol
  end

  def print_symbol(value)
    p value, :symbol
  end

  def print_indent
    @indent.times { @output << "  " }
  end

  def print_text(value)
    p value, :text
  end

  def print(value)
    @output << value
  end

  def p(value, color)
    print value.to_s.colorize(colors[color])
  end

  def namespace_definitions(node : XML::Node)
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

printer = PrettyXMLPrinter.new(STDIN, STDOUT)
printer.print
STDOUT.puts
