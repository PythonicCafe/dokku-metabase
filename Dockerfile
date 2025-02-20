FROM metabase/metabase:v0.47.3

WORKDIR /app/
ADD metabase.sh /app/

# Add custom nginx.conf template for Dokku to use
WORKDIR /app
ADD nginx.conf.sigil .

ENTRYPOINT [ ]
CMD ["/app/metabase.sh"]
