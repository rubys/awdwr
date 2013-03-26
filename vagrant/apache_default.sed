# configure suexec, enable CGI, and allow overrides
/\/var\/www\/>/ {n;s/MultiViews/MultiViews +ExecCGI/}
/\/var\/www\/>/ {n;n/s/None/All/}
/\/var\/www\/>/ a\
                AddHandler cgi-script .cgi
3 i\
        SuexecUserGroup vagrant vagrant

