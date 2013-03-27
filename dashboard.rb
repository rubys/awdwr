#!/usr/bin/ruby

require 'rubygems'
require 'wunderbar'
require 'time'
require 'yaml'

HOME = $HOME.sub(/\/?$/, '/')

config = YAML.load(open($dashboard || 'dashboard.yml'))
LOGDIR = config.delete('log').sub('$HOME/',HOME).untaint
BINDIR = config.delete('bin').sub('$HOME/',HOME).untaint

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

# identify the unique jobs
JOBS = config['book'].map do |editions|
  editions = [editions] if editions.respond_to? :push
  editions.map do |book, book_info|
    book_info['env'].map do |info|
      home = book_info['home'].sub('$HOME/',HOME)
      work=info['work']
      info['book']=book
      info['path']=File.join(home,work)
      info['id']=work.gsub('.','') + '-' + book.to_s
      info.update(book_info)
    end
  end
end.flatten

def status
  # determine if any processes are active
  active = `ps xo start,args`.
    scan(/^(?:\d\d:\d\d:\d\d|.\d:\d\d[AP]M) .*/).
    grep(/(\d |\/)testrails/)

  log = []
  unless active.empty?
    start = Time.parse(active.first.split.first)

    logs = Dir["#{LOGDIR}/makedepot*.log"]
    latest = logs.sort_by {|file| File.stat(file.untaint).mtime}.last
    if latest and File.stat(latest).mtime >= start
      log.push *open(latest) {|file| file.readlines.grep(/====>/)[-3..-1] or []}
    end

    log.map! {|line| line.chomp}
    log.unshift '' unless log.empty?
  end

  [active, log]
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
    _.submit "ruby #{BINDIR}/testrails #{@args} " +
	     "> #{LOGDIR}/post.out 2> #{LOGDIR}/post.err "

    sleep 2
  end

  active, log = status

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
          if (event.ctrlKey) {
            inputs = $('input[name=args]').val().split(/,\\s*/)
            if (inputs[0] == '') inputs.shift();
            var index = $.inArray(args, inputs);
            if (index == -1) {
              inputs.push(args);
            } else {
              inputs.splice(index, 1);
            }
            args = inputs.join(', ').replace(/,+\\s*/g, ', ')
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
    _a 'logs', :href => 'logs', :class => 'headerlink' unless @static

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
        JOBS.flatten.each do |job|
          job['path'].untaint
          statfile = "#{job['path']}/checkdepot.status"
          statfile = "#{job['path']}/status" unless File.exist? statfile
          status = open(statfile) {|file| file.read.chomp} rescue 'missing'
          status.gsub! /, 0 (pendings|omissions|notifications)/, ''
          mtime = File.stat(statfile).mtime.iso8601 rescue 'missing'

          attrs = {:id => job['id']}
          attrs[:class]='odd' if %w(3.0 3.2).include? job['rails']

          if @static
            link =  "#{job['work'].sub('work','checkdepot')}.html"
          else
            link =  "#{job['work']}/checkdepot.html"
          end

          checkdir = "#{job['path']}/checkdepot/"
          checkfile = checkdir.sub(/\/$/,'.html')
          if File.directory?(checkdir) and File.exist?(checkfile)
            if File.stat(checkdir).mtime >= File.stat(checkfile).mtime
              link.sub! ".html", '/'
            end
          end

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
            _td job['ruby'],  ({:class=>'hilite'} if job['ruby']!='2.0.0')
            _td job['rails'], ({:class=>'hilite'} if job['rails']!='4.0')
            _td :class=>color, :align=>'center' do
              if status == 'NO OUTPUT'
                link.sub! ".html", '/'
                _a status, :href => "#{job['web']}/#{link}makedepot.log"
              else
                _a status, :href => "#{job['web']}/#{link}" #todos"
              end
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
  active, log = status

  config={}
  JOBS.each do |job|
    statfile = "#{job['path']}/checkdepot.status".untaint
    statfile = "#{job['path']}/status".untaint unless File.exist? statfile

    status = open(statfile) {|file| file.read.chomp} rescue 'missing'
    status.gsub! /, 0 (pendings|omissions|notifications)/, ''
    mtime = File.stat(statfile).mtime.iso8601 rescue 'missing'
    running = File.exist?(statfile.sub('checkdepot.','')+'.run')

    config[job['id']] = {
      'status'  => status,
      'mtime'   => mtime.sub('T',' ').sub(/[+-]\d\d:\d\d$/,''),
      'running' => running
    }
  end

  _config config
  _active active + log
end
__END__
$dashboard = File.join(File.dirname(ENV['SCRIPT_FILENAME']), 'dashboard.yml')
