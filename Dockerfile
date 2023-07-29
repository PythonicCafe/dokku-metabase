FROM metabase/metabase:v0.46.6.4

WORKDIR /app/
ADD metabase.sh /app/

ENTRYPOINT [ ]
CMD ["/app/metabase.sh"]
