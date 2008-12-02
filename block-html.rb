#
# Copyright (c) 2008 Jun Kikuchi <kikuchi@bonnou.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

class BlockHTML
  attr_accessor :parent
  attr_accessor :indent

  def initialize(params={}, &block)
    @parent = nil
    @nodes  = []
    @indent = params[:indent] || 2
    block.call(self) if block_given?
  end

  def <<(tree)
    tree.parent = self
    @nodes << tree
    tree
  end

  def path(&block)
    node = if block_given?
      block.call(self)
    else
      self
    end

    if parent.nil?
      [node]
    else
      parent.path(&block).push(node)
    end
  end

  def root
    path.shift
  end

  def each(&block)
    @nodes.each(&block)
  end

  def empty?
    @nodes.empty?
  end

  def xml(attrs={})
    self << XML.new(attrs)
  end

  def doctype(attrs={})
    self << DOCTYPE.new(attrs)
  end

  def tag(tag, attrs={}, &block)
    node = self << Tag.new(tag, attrs)
    block.call(node) if block_given?
    node
  end

  def text(text='')
    self << Text.new(text)
  end

  def escaped_text(text='')
    self << EscapedText.new(text)
  end

  def render(renderer)
    each do |node|
      node.render(renderer)
    end
  end

  def to_s
    Renderer.new(self, @indent).to_s
  end

  class Attrs < ::Hash
    def to_s
      unless empty?
        ' ' + sort do |a, b|
          a.to_s <=> b.to_s
        end.map do |key, val|
          '%s="%s"' % [key, val]
        end.join(' ')
      else
        ''
      end
    end
  end

  class XML < BlockHTML
    def initialize(attrs={})
      super()
      @attrs = {
        :version  => '1.0',
        :encoding => 'utf8'
      }.merge(attrs);
    end

    def render(renderer)
      renderer.xml(@attrs)
    end
  end

  class DOCTYPE < BlockHTML
    def initialize(attrs={})
      super()
      @attrs = {
        :format  => 'xhtml',
        :version => '1.0',
        :type    => 'strict'
      }.merge(attrs);
    end

    def render(renderer)
      renderer.doctype(@attrs)
    end
  end

  class Tag < BlockHTML
    attr_reader :attrs

    def initialize(name, attrs={}, &block)
      @name = name
      @attrs = attrs.inject(Attrs.new) do |ret, (key, val)|
        ret[key] = val
        ret
      end
      super(&block)
    end

    def [](key)
      @attrs[key]
    end

    def []=(key, val)
      @attrs[key] = val
    end

    def render(renderer)
      renderer.tag(self, @name, @attrs)
    end
  end

  class Text < BlockHTML
    def initialize(text)
      super()
      @text = text
    end

    def render(renderer)
      renderer.text(@text)
    end
  end

  class EscapedText < Text
    def render(renderer)
      renderer.escaped_text(@text)
    end
  end

  class Renderer
    ESC = {
      '&' => '&amp;',
      '"' => '&quot;',
      "'" => '&#039;',
      '>' => '&gt;',
      '<' => '&lt;',
      #' ' => '&nbsp;'
    }

    ESC_STR = ESC.inject('') do |ret, (key, val)|
      ret << key
      ret
    end

    def initialize(html, indent)
      @html   = html 
      @indent = indent.to_i
      @count  = 0
      @text   = 0 < @indent
      @buf    = ''
    end

    def escape(text)
      text.clone.to_s.gsub(/[#{ESC_STR}]/n) do |val|
        ESC[val]
      end
    end

    def xml(attrs)
      @buf << '<?xml version="%s" encoding="%s"?>' % [
        attrs[:version],
        attrs[:encoding]
      ]
      @buf << "\n" if 0 < @indent
      @text = true
    end

    def doctype(attrs)
      case attrs[:format]
      when 'html5':
        @buf << '<!DOCTYPE html>'
      when 'html4':
        case attrs[:type]
        when 'strict':
          @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
        when 'frameset':
          @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">'
        else
          @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
        end
      when 'xhtml':
        if attrs[:version] == '1.1'
          @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
        else
          case attrs[:type]
          when 'strict':
            @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
          when 'frameset':
            @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'
          else
            @buf << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
          end
        end
      end

      @buf << "\n" if 0 < @indent
      @text = true
    end

    def tag(node, tag, attrs)
      space = ' ' * @count * @indent

      if node.empty?
        if 0 < @indent && !@text
          @buf << "\n%s<%s%s />" % [space, tag, attrs.to_s]
        else
          @buf << '<%s%s />' % [tag, attrs.to_s]
        end
      else
        if 0 < @indent && !@text
          @buf << "\n"
          @buf << "%s<%s%s>" % [space, tag, attrs.to_s]
        else
          @buf << '<%s%s>' % [tag, attrs.to_s]
        end
        @text = false

        @count += 1
        node.each do |obj|
          obj.render(self)
        end
        @count -= 1

        if 0 < @indent && !@text
          @buf << "\n"
          @buf << "%s</%s>" % [space, tag]
        else
          @buf << '</%s>' % [tag]
        end
      end

      @text = false
    end

    def text(text)
      @buf << escape(text)
      @text = true
    end

    def escaped_text(text)
      @buf << text
      @text = true
    end

    def to_s
      @buf = ''
      @html.render(self)
      @buf
    end
  end
end
