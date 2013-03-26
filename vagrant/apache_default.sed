# configure suexec, enable CGI, and allow overrides
3 i\
	SuexecUserGroup vagrant vagrant

/\/var\/www\/>/ {
        n
        s/MultiViews/MultiViews +ExecCGI/
        n
        s/None/All/
        a\
		AddHandler cgi-script .cgi
}
