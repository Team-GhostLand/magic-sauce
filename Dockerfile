FROM python:3
WORKDIR /app
COPY . .
CMD [ "./statd.sh" ]