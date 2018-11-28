NAME = bystrano.QZ.QZ.xrnx
CONTENT = main.lua manifest.xml README.md

DIST = dist

ZIPFILE = $(DIST)/$(NAME)

$(ZIPFILE): $(DIST) $(CONTENT)
	zip $(ZIPFILE) $(CONTENT)

$(DIST):
	@mkdir -p $(DIST)

clean:
	-rm -rf $(DIST)

.PHONY: clean
