#!/usr/bin/ruby

require 'rubygems'
require 'cgi-spa'
require 'time'
require 'yaml'

config = YAML.load(open('dashboard.yml'))
LOGDIR = config.delete('log')
BINDIR = config.delete('bin')

# identify the unique jobs
JOBS = config['book'].map do |editions|
  editions = [editions] if editions.respond_to? :push
  editions.map do |book, book_info|
    book_info['env'].map do |info|
      work=info['work']
      info['book']=book
      info['path']=File.join(book_info['home'],work)
      info['id']=work.gsub('.','') + '-' + book.to_s
      info.update(book_info)
    end
  end
end.flatten

# submit a new run in the background
$cgi.post do
  if config['path']
    ENV['PATH'] = config['path'] + File::PATH_SEPARATOR + ENV['PATH']
  end

  submit "ruby #{BINDIR}/testrails #{$param.args} " +
         "> #{LOGDIR}/post.out 2> #{LOGDIR}/post.err "

  sleep 2
end

# determine if any processes are active
ACTIVE = `ps xo start,args`.
  scan(/^(?:\d\d:\d\d:\d\d|.\d:\d\d[AP]M) .*/).
  grep(/(\d |\/)testrails/)

LOG = []
unless ACTIVE.empty?
  start = Time.parse(ACTIVE.first.split.first)

  logs = Dir["#{LOGDIR}/makedepot*.log"]
  log = logs.sort_by {|log| File.stat(log).mtime}.last
  if File.stat(log).mtime >= start
    LOG.push *open(log) {|file| file.read.grep(/====>/)[-3..-1] or []}
  end

  LOG.map! {|line| line.chomp}
  LOG.unshift '' unless LOG.empty?
end

# main output
$cgi.html do |x|
  x.header do
    x.title 'Depot Dashboard'

    x.style :type => "text/css" do
      x.indented_text! <<-'EOF'
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
        .r23 {background-color: #CCC}
        th, td {border: solid 1px; padding: 0.5em} 
        .hilite {background-color: #FF9}
        .pass {background-color: #9C9}
        .fail {background-color: #F99}
        td a, td a:visited {color: black}

        thead th:first-child {
          -webkit-border-top-left-radius: 1em;
          -moz-border-radius: 1em 0 0 0;
          border-radius: 1em 0 0 0;
        }

        thead th:last-child {
          -webkit-border-top-right-radius: 1em;
          -moz-border-radius: 0 1em 0 0;
          border-radius: 0 1em 0 0;
        }

        tfoot th:first-child {
          -webkit-border-bottom-left-radius: 1em;
          -moz-border-radius: 0 0 0 1em;
          border-radius: 0 0 0 1em;
        }

        tfoot th:last-child {
          -webkit-border-bottom-right-radius: 1em;
          -moz-border-radius: 0 0 1em 0;
          border-radius: 0 0 1em 0;
        }

      EOF
      x.indented_text! <<-'EOF' unless $param.static
        .headerlink {float: right; margin-top: -4em; margin-right: 1em}
        .headerlink {color: #282; text-decoration: none}
        #executing pre {margin-left: 5em}
        form {width: 16.2em; margin: 1em auto}
      EOF
      x.indented_text! 'form {display: none}' unless ACTIVE.empty?
      x.indented_text! '#executing {display: none}' if ACTIVE.empty?
    end

    x.script '', :src => 'jquery-1.3.2.min.js'
    x.script '', :src => 'jquery-ui-1.7.2.custom.min.js'
    x.script '', :src => 'jquery.tablesorter.min.js'

    x.script! %{
      setTimeout(update, 1000);
      function update() {
        $.getJSON("#{SELF?}", {}, function(data) {
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
        });
      }

      $(document).ready(function() {
        $('tr td:nth-child(5)').click(function() {
          var parent = $(this).parent();
          $('input[name=args]').val(
            parent.find('td:eq(0)').text().replace(/\\D/g,'') + ' ' +
            parent.find('td:eq(1)').text().replace(/\\D/g,'') + ' ' +
            parent.find('td:eq(2)').text().replace(/\\D/g,'')
          );
          $(this).css({backgroundColor: '#ff0'}); 
          $(this).animate({backgroundColor: '#fff'}, 'slow'); 
          $('input[name=args]').css({backgroundColor: '#f70'}); 
          $('input[name=args]').animate({backgroundColor: '#fff'}, 'slow'); 
        });
      });
    } unless $param.static

    x.script! %{
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

  x.body do
    x.h1 'The Depot Dashboard'
    x.a 'logs', :href => 'logs', :class => 'headerlink' unless $param.static

    x.table do
      x.thead do
        x.tr do
          x.th 'Book'
          x.th 'Ruby'
          x.th 'Rails'
          x.th 'Status'
          x.th 'Time'
        end
      end

      x.tbody do
        JOBS.flatten.each do |job|
          statfile = "#{job['path']}/status"
          status = open(statfile) {|file| file.read.chomp} rescue 'missing'
          status.gsub! /, 0 (pendings|omissions|notifications)/, ''
          mtime = File.stat(statfile).mtime.iso8601 rescue 'missing'

          attrs = {:id => job['id']}
          attrs[:class]='r23' if job['rails']=='3.0'

          if $param.static
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

          if File.exist?(statfile+'.run')
            color = 'hilite'
          elsif status =~ / 0 failures, 0 errors/
            color = 'pass'
          else
            color = 'fail'
          end

          x.tr attrs do
            x.td job['book'], {:align=>'right'}.
              merge(job['book']=='4' ? {} : {:class=>'hilite'})
            x.td job['ruby'],  ({:class=>'hilite'} if job['ruby']!='1.8.7')
            x.td job['rails'], ({:class=>'hilite'} if job['rails']!='3.1')
            x.td :class=>color, :align=>'center' do
              if status == 'NO OUTPUT'
                link.sub! ".html", '/'
                x.a status, :href => "#{job['web']}/#{link}makedepot.log"
              else
                x.a status, :href => "#{job['web']}/#{link}" #todos"
              end
            end
            x.td mtime.sub('T',' ').sub(/[+-]\d\d:\d\d$/,'')
          end
        end
      end

      x.tfoot do
        x.tr do
          5.times { x.th '' }
        end
      end
    end

    unless $param.static
      x.form :method=>'post' do
        x.input :name=>'args'
        x.input :type=>'submit', :value=>'submit'
      end

      x.div :id=>'executing' do
        x.h2 'Currently Executing'
        x.pre ACTIVE.join("\n"), :id => 'active'
      end
    end
  end
end

# dynamic status updates
$cgi.json do
  config={}
  JOBS.each do |job|
    statfile = "#{job['path']}/status"

    status = open(statfile) {|file| file.read.chomp} rescue 'missing'
    status.gsub! /, 0 (pendings|omissions|notifications)/, ''
    mtime = File.stat(statfile).mtime.iso8601 rescue 'missing'
    running = File.exist?(statfile+'.run')

    config[job['id']] = {
      'status'  => status,
      'mtime'   => mtime.sub('T',' ').sub(/[+-]\d\d:\d\d$/,''),
      'running' => running
    }
  end

  {'config'=>config, 'active'=>ACTIVE + LOG}
end
