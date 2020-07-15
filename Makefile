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
	for lang in $$(ls "$${TEMP}" -S); \
	do  quant="$$(cat "$${TEMP}/$${lang}" | wc -l)"; \
		NUMB="$$((NUMB + quant))"; \
		color=$$(echo "obase=16;$${NUMB}" | bc | awk '{ print("00000"$$1); }' | tail -c4); \
		printf "![](https://img.shields.io/badge/-%s-%s?style=flat-square&logo=%s&logoColor=fff)" "$${lang}" "$${color}" "$${lang}"; \
	done > badges.md; sed -e '/^.*Σ.*$$/e cat badges.md' -e 's/^.*Σ.*$$//' $(TARGET) > README.tmp; mv README.tmp $(TARGET); \
	rm -Rf badges.md langs.json "$${TEMP}"


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
