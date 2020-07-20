#
# 🜏
#
# For further information see `README.md`.
#
TARGET?= README.md

ifneq (,$(DESTDIR))
TARGET =$(DESTDIR)
endif

CMD = "\\e[1m%-10s\\e[0m%s\n"
STR = "\\e[0;2;3m%s\\e[0m\n"
HLP = sed -E 's/(`.*`)/\\e[1m\1\\e[0m/'



DEFAULT: help

accidents: # Update X days since last accident.
	@\
	echo "0 days since last accident"

languages: # Populate your README.md with badges of your most used languages.
	@\
	curl -H "Authorization: bearer $${TOKEN}" -X POST -d "\
	{\"query\": \"query{ viewer{ login, repositories(last:100){ nodes{ name, languages(last:100){ nodes{ lang: name }}}}}, rateLimit{ remaining }}\" \
	}" https://api.github.com/graphql > langs.json; \
	NUMB=0; \
	TEMP="$$(mktemp -d)"; \
	for lang in $$(cat langs.json  | grep 'lang":"\w*"' -o | sed -E 's/.*:"(.*)"/\1/'); \
	do  echo >> "$${TEMP}/$${lang}"; \
		echo >> "$${TEMP}/Σ"; \
	done; \
	for el in $$(ls "$${TEMP}" -S); \
	do  lang="$${el}"; \
		QTDE="$$(cat "$${TEMP}/$${lang}" | wc -l)"; \
		NUMB="$$((NUMB + QTDE))"; \
		color=$$(echo "obase=16;$${NUMB}" | bc | awk '{ print("00000"$$1); }' | tail -c4); \
		printf "![](https://img.shields.io/badge/-%s-%s?style=flat-square&logo=%s&logoColor=fff)" "$${lang}" "$${color}" "$${lang}"; \
	done > badges.md; sed -e '/^.*Σ.*$$/e cat badges.md' -e 's/^.*Σ.*$$//' $(TARGET) > README.tmp; mv README.tmp $(TARGET); \
	rm -Rf badges.md langs.json "$${TEMP}"

books: # Recomended books
	@\
	e=echo; \
	c=curl; \
	k="Nothing to do.."; \
	TMP="$$(mktemp -d)"; \
	URL="https://www.googleapis.com/books/v1/volumes?q="""""""""; \
	sanitize='s/\//\\\//g;s/\[/\\\[/g;s/\]/\\\]/g;s/\:/\\\:/g'''; \
	for E in $$(cat README.md | grep -e '''\[book-.*\]\:$$'''''); \
	do  data=$$($$e "$${E}"   | sed  -E 's/\[book-(.*)]:.*/\1/'); \
		book=$$($$c "$${URL}$${data}" > "$${TMP}/$${data}.temp"; cat "$${TMP}/$${data}.temp"); \
		name=$$($$e "$${book}" | grep 'title"' | head -n1 | sed -E 's/.*itle": "(.*)".*/\1/'); \
		pict=$$($$e "$${book}" | grep 'thumbn' | head -n1 | sed -E 's/.*nail": "(.*)".*/\1/'); \
		from=$$($$e "$${E}"    | sed -E "$${sanitize}"); \
		safe=$$($$e "![$${name}][book-$${data}]" | sed -E "$${sanitize}"); \
		$$e "$${E}" "$${pict}" >> "$${TMP}/books.md"; \
		sed -E "s/^$${from}$$/$${safe}/" "README.md""" > """$${TMP}/README.md" && mv "$${TMP}/README.md" "README.md"; \
	done; [ -e "$${TMP}/books.md" ] && cat "$${TMP}/books.md" >> "./README.md" || $$e $$k

#
help: # Shows this help.
	@\
	echo """"""""""""""""""""""""""" \
	$$(awk 'BEGIN {   FS=":.*?#"   } \
	/^(\w+:.*|)#/ {                  \
	gsub("^( : |)#( |)", """""""" ); \
	LEN=length($$2); COND=(LEN < 1); \
	FORMAT=(COND ? $(STR) : $(CMD)); \
	printf(FORMAT, $$1, """"""$$2 ); \
	}' $(MAKEFILE_LIST) | ($(HLP)))"


#
%:
	@:
