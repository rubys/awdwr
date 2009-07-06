require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'active_support/version'

module Book
end

class Book::TestCase < ActiveSupport::TestCase
  # just enough infrastructure to get 'assert_select' to work
  require 'action_controller'
  require 'action_controller/assertions/selector_assertions'
  include ActionController::Assertions::SelectorAssertions

  # micro DSL allowing the definition of optional tests
  def self.section number, title, &tests
    return if ARGV.include? 'partial' and !@@sections.has_key? number.to_s
    test "#{number} #{title}" do
      instance_eval {select number}
      instance_eval &tests
    end
  end

  # read and pre-process $input.html (only done once, and cached)
  def self.input filename
    # read $input output; remove front matter and footer
    input = open("#{filename}.html").read
    head, body, tail = input.split /<body>\s+|\s+<\/body>/m

    # split into sections
    @@sections = body.split(/<a class="toc" name="section-(.*?)">/)

    # convert to a Hash
    @@sections = Hash[*@@sections.unshift(:contents)]
    @@sections[:head] = head
    @@sections[:tail] = tail

    # reattach anchors
    @@sections.each do |key,value|
      next unless key =~ /^\d/
      @@sections[key] = "<a class=\"toc\" name=\"section-#{key}\">#{value}"
    end

    # report version
    body =~ /rails .*?-v<\/pre>\s+.*?>(.*)<\/pre>/
    @@version = $1
    @@version += ' (git)' if body =~ /ln -s.*vendor.rails/
    @@version += ' (edge)' if body =~ /rails:freeze:edge/
    STDERR.puts @@version
  end

  def self.output filename
    $output = filename
    at_exit { HTMLRunner.run(self) }
  end

  # select an individual section from the HTML
  def select number
    raise "Section #{number} not found" unless @@sections.has_key? number.to_s
    @selected = HTML::Document.new(@@sections[number.to_s]).root.children
    assert @@sections[number.to_s] !~
      /<pre class="traceback">\s+#&lt;IndexError: regexp not matched&gt;/,
      "edit failed"
  end

  def collect_stdout
    css_select('.stdout').map do |tag|
      tag.children.join.gsub('&lt;','<').gsub('&gt;','>')
    end
  end

  def sort_hash line
    line.sub(/^(=> )?\{.*\}$/) do |match|
      "#{$1}{#{match.scan(/:?"?\w+"?=>[^\[].*?(?=, |\})/).sort.join(', ')}}"
    end
  end

  def self.sections
    @@sections
  end
end

# insert failure indicators into #{output}.html
require 'test/unit/ui/console/testrunner'
class HTMLRunner < Test::Unit::UI::Console::TestRunner
  def attach_to_mediator
    super
    @html_tests = []
    @mediator.add_listener(Test::Unit::TestResult::FAULT,
      &method(:html_fault))
    @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED,
      &method(:html_summary))
  end

  def html_fault fault
    if fault.test_name =~ /^test_([\d.]+)_.*\(\w+\)$/
      name = $1
      sections = DepotTest.sections
      return unless sections.has_key? name

      # indicate failure in the toc
      sections[:contents][/<a href="#section-#{name}"()>/,1] = 
        ' style="color:red; font-weight:bold"'

      # provide details in the section itself
      x = Builder::XmlMarkup.new(:indent => 2)
      x.pre fault.message.sub(".\n<false> is not true",'') +
        "\n\nTraceback:\n  " + fault.location.join("\n  "),
        :class=>'traceback'
      sections[name][/<\/a>()/,1] = x.target!
    end
  end

  def html_summary elapsed
    open("#{$output}.html",'w') do |output|
      sections = DepotTest.sections
      output.write(sections.delete(:head))
      output.write("<body>\n    ")
      output.write(sections.delete(:contents))
      tail = sections.delete(:tail)
      sections.keys.sort_by {|key| key.split('.').map {|n| n.to_i}}.each do |n|
        output.write(sections[n])
      end
      output.write("\n  </body>")
      output.write(tail)
    end
  end
end
