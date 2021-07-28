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
	[ ! -e langs.json ] && \
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
		printf "![lang %-10s](https://img.shields.io/badge/-%s-%s?style=flat-square&logo=%s&logoColor=fff)\n" "$${lang}" "$${lang}" "$${color}" "$${lang}"; \
	done > badges.md; sed -e '/^!\[lang.*$$/d; /Most used languages$$/a Σ' $(TARGET); sed -e '/^Σ$$/e cat badges.md' $(TARGET) -e '/^[|.]*Σ.*$$/d' > README.tmp; mv README.tmp $(TARGET); \
	rm -Rf badges.md langs.json "$${TEMP}"

books: # Recomended books
	@\
	o() { echo "$$*"; }; \
	c() { curl "$$1"; }; \
	export o; \
	export c; \
	k="Nothing to do.."; \
	TMP="$$(mktemp -d)"; \
	BOOKS="$${TMP}/books.md"; \
	README="$${TMP}/README.md"; \
	URL="https://www.googleapis.com/books/v1/volumes?q="""""""""; \
	sanitize='s/\//\\\//g;s/\[/\\\[/g;s/\]/\\\]/g;s/\:/\\\:/g'''; \
	for E in $$(cat README.md | grep -e '''\[book-.*\]\:$$'''''); \
	do  data=$$(o "$${E}"   | sed  -E 's/\[book-(.*)]:.*/\1/'); \
		book=$$(c "$${URL}$${data}" > "$${TMP}/$${data}.temp"; cat "$${TMP}/$${data}.temp"); \
		name=$$(o "$${book}" | grep 'title"' | head -n1 | sed -E 's/.*itle": "(.*)".*/\1/'); \
		pict=$$(o "$${book}" | grep 'thumbn' | head -n1 | sed -E 's/.*nail": "(.*)".*/\1/'); \
		from=$$(o "$${E}"    | sed -e 's/∴/./' | sed -E "$${sanitize}"); \
		safe=$$(o "![$${name}][book-$${data}]" | sed -E "$${sanitize}"); \
		[ ! -e "$${BOOKS}" ] && o >"$${BOOKS}"; \
		o "$${E}" "$${pict}""" >>"""$${BOOKS}"; \
		sed -E "s/^$${from}$$/$${safe}/" "README.md" > \
		"$${README}" && (mv "$${README}" "README.md"); \
	done; [ -e "$${BOOKS}" ] \
		&& cat "$${BOOKS}" >> "./README.md" \
		|| ( o "$$k")

covers: # Process book covers
	@go run book-covers.go

clean: # Remove temporary files.
	@rm -Rf temporary*

#
help: # Shows this help.
	@\
	echo -e """""""""""""""""""""""  \
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
