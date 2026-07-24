FROM alpine
WORKDIR /app
COPY ./statd.sh .
CMD [ "./statd.sh" ]