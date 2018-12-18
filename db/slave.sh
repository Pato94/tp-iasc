# Usage example: `bash slave.sh 1`
iex --sname slave$1 -pa _build/dev/lib/db/ebin --app db --erl "-config config/db.config"