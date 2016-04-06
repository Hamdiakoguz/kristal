# XML pretty printer
# ~~~~~~~~~~~~~~~~~~~
#
# Reads XML from STDIN and outputs it formatted and colored to STDOUT.
# Incomplete implementation, adapted from crystal json sample. Just for trying out crystal.
#
# Usage: echo '<?xml version="1.0"?><name><first>Cahit</first><last>Arf</last></name>' | ./pretty_xml

require "xml"
require "colorize"

class PrettyXMLPrinter
  def initialize(@input, @output)
    @doc = XML.parse(@input)
    @indent = 0
  end

  def print
    print_node(@doc)
  end

  def print_node(node)
    if node.type == XML::Type::TEXT_NODE
      unless node.content.nil? || node.content =~ /^\s*$/
        # print node.type
        print "\n"
        print_indent
        print node.content
      end
      return
    end

    print "\n"
    print_indent

    open_tag(node)

    node.children.each do |child|
      @indent += 1
      print_node(child)
      @indent -= 1
    end

    print "\n"
    print_indent
    close_tag(node)
  end

  def open_tag(node)
    print "<".colorize.blue
    print node.name.colorize.red
    node.attributes.each do |attr|
      print ' '
      print attr.name.colorize.yellow
      print "=\"".colorize.blue
      print attr.content.colorize.yellow
      print '"'.colorize.blue
    end
    print ">".colorize.blue
  end

  def close_tag(node)
    print "</".colorize.blue
    print node.name.colorize.red
    print ">".colorize.blue
  end

  def print_indent
    @indent.times { @output << "  " }
  end

  def print(value)
    @output << value
  end
end

printer = PrettyXMLPrinter.new(STDIN, STDOUT)
printer.print
STDOUT.puts
