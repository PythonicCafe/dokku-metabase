FROM metabase/metabase:v0.46.6.1

WORKDIR /app/
ADD metabase.sh /app/

ENTRYPOINT [ ]
CMD ["/app/metabase.sh"]
