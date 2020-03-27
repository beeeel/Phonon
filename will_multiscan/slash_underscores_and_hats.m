%out=slash_underscores_and_hats(in);
function out=slash_underscores_and_hats(in);
underscore = findstr(in,'_');
out = in;
for l = length(underscore):-1:1
	s = length(out);
	out = strcat(out(1:underscore(l)-1),'\_',out(underscore(l)+1:s));
	end;
hat = findstr(out,'^');
for l = length(hat):-1:1
	s = length(out);
	out = strcat(out(1:hat(l)-1),'\^',out(hat(l)+1:s));
	end;
