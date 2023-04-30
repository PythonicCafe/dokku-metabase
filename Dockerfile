FROM metabase/metabase:v0.46.2

WORKDIR /app/
ADD metabase.sh /app/

ENTRYPOINT [ ]
CMD ["/app/metabase.sh"]
