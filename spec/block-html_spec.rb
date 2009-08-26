require 'lib/block-html'

describe BlockHTML do
  describe 'インターフェース' do
    before do
      @bhtml = BlockHTML.new
    end

    it 'インスタンス' do
      %w'parent << path root each empty? xml doctype tag text escaped_text render to_s'.each do |val|
        @bhtml.should respond_to val.to_sym
      end
    end
  end

  describe '空の状態' do
    before do
      @bhtml = BlockHTML.new
    end

    it 'parent == nil' do
      @bhtml.parent.should be_nil
    end

    it 'path == []' do
      @bhtml.path.should == [@bhtml]
    end

    it 'root == self' do
      @bhtml.root.should == @bhtml
    end

    it 'each' do
      @bhtml.each do |b|
        b.should == @bhtml
      end
    end

    it 'empty? == true' do
      @bhtml.empty?.should be_true
    end

    it 'to_s == ""' do
      @bhtml.to_s.should == ''
    end
  end

  describe 'ノードを１つ追加する操作' do
    before do
      @bhtml = BlockHTML.new
    end

    it 'xml' do
      @bhtml.xml
      @bhtml.to_s.should == '<?xml version="1.0" encoding="utf8"?>'
    end

    it 'xml(:version => "1.1", :encoding => "sjis")' do
      @bhtml.xml :version => '1.1', :encoding => 'sjis'
      @bhtml.to_s.should == '<?xml version="1.1" encoding="sjis"?>'
    end

    it 'doctype(:version => "1.1")' do
      @bhtml.doctype :version => '1.1'
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
    end

    it 'doctype' do
      @bhtml.doctype
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    end

    it 'doctype(:type => "strict")' do
      @bhtml.doctype :type => 'strict'
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    end

    it 'doctype(:type => "frameset")' do
      @bhtml.doctype :type => 'frameset'
      @bhtml.to_s.should =='<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'
    end

    it 'doctype(:type => nil)' do
      @bhtml.doctype :type => nil
      @bhtml.to_s.should =='<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
    end

    it 'doctype(:format => "html4")' do
      @bhtml.doctype :format => 'html4'
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    end

    it 'doctype(:format => "html4", :type => "strict")' do
      @bhtml.doctype :format => 'html4', :type => 'strict'
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    end

    it 'doctype(:format => "html4", :type => "frameset")' do
      @bhtml.doctype :format => 'html4', :type => 'frameset'
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">'
    end

    it 'doctype(:format => "html4", :type => nil)' do
      @bhtml.doctype :format => 'html4', :type => nil
      @bhtml.to_s.should == '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
    end

    it 'doctype(:format => "html5")' do
      @bhtml.doctype :format => 'html5'
      @bhtml.to_s.should == '<!DOCTYPE html>'
    end

    it 'tag' do
      @bhtml.tag 'p'
      @bhtml.to_s.should == '<p />'
    end

    it 'tag("a", :href => "/", :id => "abc")' do
      @bhtml.tag 'a', :href => '/', :id => 'abc'
      @bhtml.to_s.should == '<a href="/" id="abc" />'
    end

    it 'text("aaa")' do
      @bhtml.text 'aaa'
      @bhtml.to_s.should == 'aaa'
    end

    it 'text("<a>")' do
      @bhtml.text '<a>'
      @bhtml.to_s.should == '&lt;a&gt;'
    end

    it 'escaped_text("aaa")' do
      @bhtml.escaped_text 'aaa'
      @bhtml.to_s.should == 'aaa'
    end

    it 'escaped_text("<a>")' do
      @bhtml.escaped_text '<a>'
      @bhtml.to_s.should == '<a>'
    end
  end

  describe 'ノードを幾つか追加する操作' do
    before do
      @bhtml = BlockHTML.new
    end

    it '@bhtml.tag("p").text("aaa")' do
      @bhtml.tag("p").text("aaa").to_s.should == '<p>aaa</p>'
    end

    it '@bhtml.tag("p", :id => "abc").text("aaa")' do
      @bhtml.tag("p", :id => "abc").text("aaa").to_s.should == '<p id="abc">aaa</p>'
    end

    it '@bhtml.tag("p") { tag("br") }' do
      @bhtml.tag("p") { tag('br') }.to_s.should == '<p><br /></p>'
    end

    it '@bhtml.tag("p") { tag("p").text(hello) }' do
      hello = 'Hello'
      @bhtml.tag("p") {
        tag('p').text(hello)
      }.to_s.should == '<p><p>Hello</p></p>'
    end

    describe 'インデントを設定' do
      before do
        @bhtml = BlockHTML.new
      end

      it '@bhtml.tag("div") { tag("p") { text("Hello") } }' do
        @bhtml.tag("div") {
          tag("p") { text("Hello") }
        }
        @bhtml.to_s(2).should == "<div>\n  <p>Hello</p>\n</div>"
      end
    end
  end
end
