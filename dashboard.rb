#!/usr/bin/ruby

require 'rubygems'
require 'wunderbar/job-control'
require 'time'
require 'yaml'

$home = $HOME.sub(/\/?$/, '/')
home_re = /(\$HOME|\~)\//

$dashboard = File.join(File.dirname(__FILE__), 'dashboard.yml')
config = YAML.load_file($dashboard)
$logdir = config.delete('log').sub(home_re, $home).untaint
$bindir = config.delete('bin').sub(home_re, $home).untaint

testrails = config.delete('testrails').to_s.sub /^\~\//, ENV['HOME'] + '/'
testrails = YAML.load_file(testrails.untaint) if testrails

# set up symbolic links
if ARGV == ['--symlink']
  config['book'].each do |edition|
    edition.each do |name, vars|
      unless File.exist? vars['web']
        system "ln -s #{vars['home']} #{vars['web']}"
      end
    end
  end
  exit
end

require "#{$home}/git/awdwr/environment".untaint

# identify the unique jobs
$jobs = config['book'].map do |editions|
  editions = [editions] if editions.respond_to? :push
  editions.map do |book, book_info|
    book_info['env'].map do |info|
      if testrails
        rails = info['rails'].gsub('.', '')
        ruby  = info['ruby'].gsub('.', '')
        info = AWDWR::config(testrails, book, rails, ruby).merge(info)
      else
        info['source'] = book_info['home'].sub(home_re ,HOME)
      end
      info['book']=book
      info['path']=File.join(info['source'], info['work']).untaint
      info['id']=info['work'].gsub('.','') + '-' + book.to_s
      info.update(book_info)
    end
  end
end.flatten

module Dashboard
  def self.status
    # determine if any processes are active
    active = `ps xo start,args`.
      scan(/^(?:\d\d:\d\d:\d\d|.\d:\d\d[AP]M) .*/).
      grep(/(\d |\/)testrails/)

    log = []
    unless active.empty?
      start = Time.parse(active.first.split.first)

      logs = Dir["#{$logdir}/makedepot*.log"]
      latest = logs.sort_by {|file| File.stat(file.untaint).mtime}.last
      if latest and File.stat(latest).mtime >= start
        log.push *open(latest) {|file| file.readlines.grep(/====>/).pop(3)}
      end

      log.map! {|line| line.chomp.sub('====> ','')}
      log.unshift '' unless log.empty?
    end

    [active, log]
  end

  # checkdepot link for a given job
  def self.checkdepot(job, status, static=false)
    if static
      link = "#{job['work'].sub('work','checkdepot')}.html"
    else
      link = "#{job['work']}/checkdepot.html"
    end

    checkdir = "#{job['path']}/checkdepot/"
    checkfile = checkdir.sub(/\/$/,'.html')
    if File.directory?(checkdir) and File.exist?(checkfile)
      if File.stat(checkdir).mtime >= File.stat(checkfile).mtime
        link.sub! ".html", '/'
      end
    end

    if status == 'NO OUTPUT'
      link= "#{link.sub('.html','/')}makedepot.log"
    end

    "#{job['web']}/#{link}"
  end
end

# main output
_html do

  # submit a new run in the background
  if _.post?
    if config['path']
      ENV['PATH'] = config['path'] + File::PATH_SEPARATOR + ENV['PATH']
    end

    require 'shellwords'
    @args = Shellwords.join(@args.split).untaint
    _.submit "ruby #{$bindir}/testrails #{@args} " +
	     "> #{$logdir}/post.out 2> #{$logdir}/post.err "

    sleep 2
  end

  active, log = Dashboard.status

  _head_ do
    _title 'Depot Dashboard'

    _style :type => "text/css" do
      _ <<-'EOF'
        body {margin:0; background: #f5f5dc}

        h1 {
          background: #9C9; color: #282; text-align: center;
          font: 40px "Times New Roman",serif;
          font-weight: normal; font-variant: small-caps;
          padding: 10px 0; border-bottom: 2px solid; margin: 0 0 0.5em 0;
       }

        h2 {border-spacing: 0; margin-left: 2em}

        table {border-spacing: 0; margin-left: auto; margin-right:auto}
        th {color: #000; background-color: #99C; border: solid #000 1px}
        .odd {background-color: #CCC}
        th, td {border: solid 1px; padding: 0.5em} 
        .selected td:nth-child(5) {border: 3px solid #d2691e} 
        .hilite {background-color: #FF9}
        .pass {background-color: #9C9}
        .fail {background-color: #F99}
        td a, td a:visited {color: black}

        thead th:first-child { border-radius: 1em 0 0 0 }
        thead th:last-child { border-radius: 0 1em 0 0 } 
        tfoot th:first-child { border-radius: 0 0 0 1em }
        tfoot th:last-child { border-radius: 0 0 1em 0 }
      EOF
      _ <<-'EOF' unless @static
        .deploylink {float: left; margin-top: -4em; margin-left: 1em}
        .deploylink {color: #282; text-decoration: none}
        .headerlink {float: right; margin-top: -4em; margin-right: 1em}
        .headerlink {color: #282; text-decoration: none}
        #executing pre {margin-left: 5em}
        form {width: 16.2em; margin: 1em auto}
      EOF
      _ 'form {display: none}' unless active.empty?
      _ '#executing {display: none}' if active.empty?
    end

    _script :src => 'jquery.min.js'
    _script :src => 'jquery-ui.min.js'
    _script :src => 'jquery.tablesorter.min.js'

    _script %{
      setTimeout(update, 1000);
      function update() {
        $.post("", {}, function(data) {
          for (var id in data.config) {
            var line = data.config[id];
            $('#'+id+' td:eq(3) a').attr('href', line.link);
            $('#'+id+' td:eq(3) a').text(line.status);
            $('#'+id+' td:eq(4)').text(line.mtime);

            if (line.running) {
              $('#'+id+' td:eq(3)').addClass('hilite').
                removeClass('pass').removeClass('fail');
            } else if (line.status.match(/ 0 failures, 0 errors/)) {
              $('#'+id+' td:eq(3)').addClass('pass').
                removeClass('hilite').removeClass('fail');
            } else {
              $('#'+id+' td:eq(3)').addClass('fail').
                removeClass('hilite').removeClass('pass');
            }
          }

          if (data.deploy) {
            $('.deploylink').show();
          } else {
            $('.deploylink').hide();
          }

          if (data.active.length == 0) {
            $('form').show();
            $('#executing').hide();
          } else {
            $('form').hide();
            $('#executing').show();
            $('#active').text(data.active.join("\\n"));
          }

          $('table').trigger('update');
          setTimeout(update, 5000);
        }, 'json');
      }

      $(document).ready(function() {
        $('tr td:nth-child(5)').click(function(event) {
          var parent = $(this).parent();
          var args =
            parent.find('td:eq(0)').text().replace(/\\D/g,'') + ' ' +
            parent.find('td:eq(1)').text().replace(/\\D/g,'') + ' ' +
            parent.find('td:eq(2)').text().replace(/\\D/g,'');
          if (parent.find('td:eq(0)').text() == 'svn') args = 'svn' + args;
          if (event.ctrlKey || event.shiftKey || event.metaKey) {
            inputs = $('input[name=args]').val().split(/,\\s*/)
            if (inputs[0] == '') inputs.shift();
            var index = $.inArray(args, inputs);
            if (index == -1) {
              inputs.push(args);
              parent.addClass('selected');
            } else {
              inputs.splice(index, 1);
              parent.removeClass('selected');
            }
            args = inputs.join(', ').replace(/,+\\s*/g, ', ')
          } else {
            $('tr').removeClass('selected');
            parent.addClass('selected');
          }
          $('input[name=args]').val(args);
          $(this).css({backgroundColor: '#ff0'}); 
          $(this).animate({backgroundColor: '#fff'}, 'slow'); 
          $('input[name=args]').css({backgroundColor: '#f70'}); 
          $('input[name=args]').animate({backgroundColor: '#fff'}, 'slow'); 
        });
      });
    } unless @static

    _script! %{
      $(document).ready(function() {
        $.tablesorter.addParser({
          id: 'summary',
          is: function(s) {return false},
          format: function(value, table, cell) {
            var vals = $(cell).text().match(/\d+/g);
            if (!vals) return '9999';
            if (vals.length == 4) {
              vals = [vals[3],vals[2],9999-vals[0],9999-vals[1]];
            }
            var rjust = function(x) {
              return ('000'+x).substr(x.toString().length-1,4)
            };
            return vals.map(rjust).join('');
          },
          type: 'text'
        });

        $('table').tablesorter({headers: {3:{sorter:'summary'}}});
      });
    }
  end

  _body do
    _h1 'The Depot Dashboard'
    unless @static
      deploy = File.join(File.dirname($dashboard), 'checkdeploy.html')
      _a 'deploy', :href => 'checkdeploy', :class => 'deploylink',
        :style => ('display: none' unless File.exist? deploy.untaint)
      _a 'logs', :href => 'logs', :class => 'headerlink'
    end

    _table_ do
      _thead do
        _tr do
          _th 'Book'
          _th 'Ruby'
          _th 'Rails'
          _th 'Status'
          _th 'Time'
        end
      end

      _tbody_ do
        $jobs.flatten.each do |job|
          statfile = "#{job['path']}/checkdepot.status"
          statfile = "#{job['path']}/status" unless File.exist? statfile
          status = open(statfile) {|file| file.read.chomp} rescue 'missing'
          status.gsub! /, 0 (pendings|omissions|notifications)/, ''
          mtime = File.stat(statfile).mtime.iso8601 rescue 'missing'

          attrs = {:id => job['id']}
          attrs[:class]='odd' if %w(4.0 4.2).include? job['rails']

          if File.exist?(statfile.sub('checkdepot.','')+'.run')
            color = 'hilite'
          elsif status =~ / 0 failures, 0 errors/
            color = 'pass'
          else
            color = 'fail'
          end

          _tr_ attrs do
            _td job['book'], {:align=>'right'}.
              merge(job['book']=='4' ? {} : {:class=>'hilite'})
            _td job['ruby'],  ({:class=>'hilite'} if job['ruby']!='2.1.5')
            _td job['rails'], ({:class=>'hilite'} if job['rails']!='5.0')
            _td :class=>color, :align=>'center' do
              _a status, :href => Dashboard.checkdepot(job, status, @static)
            end
            _td mtime.sub('T',' ').sub(/[+-]\d\d:\d\d$/,'')
          end
        end
      end

      _tfoot do
        _tr do
          5.times { _th '' }
        end
      end
    end

    unless @static
      _form :method=>'post' do
        _input :name=>'args'
        _input :type=>'submit', :value=>'submit'
      end

      _div_ :id=>'executing' do
        _h2 'Currently Executing'
        _pre active.join("\n"), :id => 'active'
      end
    end
  end
end

# dynamic status updates
_json do
  active, log = Dashboard.status

  config={}
  $jobs.each do |job|
    statfile = "#{job['path']}/checkdepot.status"
    statfile = "#{job['path']}/status" unless File.exist? statfile

    status = open(statfile) {|file| file.read.chomp} rescue 'missing'
    status.gsub! /, 0 (pendings|omissions|notifications)/, ''
    mtime = File.stat(statfile).mtime.iso8601 rescue 'missing'
    running = File.exist?(statfile.sub('checkdepot.','')+'.run')

    config[job['id']] = {
      'status'  => status,
      'mtime'   => mtime.sub('T',' ').sub(/[+-]\d\d:\d\d$/,''),
      'running' => running,
      'link'    => Dashboard.checkdepot(job, status)
    }
  end

  webdir = File.dirname($dashboard)
  _deploy File.exist? File.join(webdir, 'checkdeploy.html').untaint
  _config config
  _active active + log
end
__END__
$dashboard = File.join(File.dirname(ENV['SCRIPT_FILENAME']), 'dashboard.yml')
