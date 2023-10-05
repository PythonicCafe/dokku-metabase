FROM metabase/metabase:v0.47.3

WORKDIR /app/
ADD metabase.sh /app/

ENTRYPOINT [ ]
CMD ["/app/metabase.sh"]
